# ==============================================================================
# UNIVERSIDAD DEL QUINDÍO - PROGRAMACIÓN III
# JOAN SEBASTIAN VARGAS
# ARCHIVO PRINCIPAL: main.exs (CON VENTANAS GRÁFICAS REALES Y
# EXUNIT CAPTUREIO este comando permite capturar la salida de IO.puts y IO.inspect)
# ==============================================================================

# 1. Inicializar ExUnit para capturar salidas
ExUnit.start()
import ExUnit.CaptureIO

Code.require_file("datos.exs")
Code.require_file("liquidacion.exs")

# ------------------------------------------------------------------------------
# MÓDULO GUI NATIVO DE WINDOWS (JOptionPane sin fallos ni bloqueos)
# ------------------------------------------------------------------------------
defmodule JOptionPane do
  @doc "Muestra un cuadro de entrada flotante en Windows"
  def input_dialog(mensaje, titulo) do
    # Archivo temporal con VBScript para pedir datos en pantalla
    vbs_content = """
    Dim input
    input = InputBox("#{mensaje}", "#{titulo}")
    WScript.Echo input
    """

    temp_vbs = Path.join(System.tmp_dir!(), "input_dialog.vbs")
    File.write!(temp_vbs, vbs_content)

    res =
      case System.cmd("cscript", ["//Nologo", temp_vbs]) do
        {salida, 0} -> String.trim(salida)
        _ -> ""
      end

    File.rm(temp_vbs)
    res
  end

  @doc "Muestra un reporte largo en una ventana flotante con scroll"
  def message_dialog(mensaje, titulo) do
    # Crea un archivo HTML temporal con CSS para dar estilo de ventana emergente
    html_content = """
    <html>
    <head>
      <title>#{titulo}</title>
      <HTA:APPLICATION ID="oHTA" SCROLL="auto" WINDOWSTATE="normal">
      <style>
        body { font-family: 'Consolas', monospace; background-color: #1e1e1e; color: #d4d4d4; padding: 15px; }
        pre { font-size: 13px; white-space: pre-wrap; word-wrap: break-word; }
        button { background-color: #0e639c; color: white; border: none; padding: 10px 20px; cursor: pointer; font-size: 14px; margin-top: 10px; }
        button:hover { background-color: #1177bb; }
      </style>
    </head>
    <body onload="window.resizeTo(800, 650); window.focus();">
      <pre>#{String.replace(mensaje, "<", "&lt;")}</pre>
      <center><button onclick="window.close();">Aceptar / Cerrar</button></center>
    </body>
    </html>
    """

    temp_html = Path.join(System.tmp_dir!(), "reporte_dialog.hta")
    File.write!(temp_html, html_content)

    # Abre la ventana MSHTA nativa de Windows
    System.cmd("mshta.exe", [temp_html])

    File.rm(temp_html)
    :ok
  end
end

# ------------------------------------------------------------------------------
# LECTURA DINÁMICA CON VENTANAS FLOTANTES
# ------------------------------------------------------------------------------

# 1. Repartidores
rep_input = JOptionPane.input_dialog(
  "OPCIONAL: Ingrese un nuevo repartidor (Código;Nombre;UsaBici)\\nEjemplo: M11;Carlos Restrepo;true\\n\\n(Deje en blanco o Cancele para omitir):",
  "Registro de Repartidor"
)

nuevo_rep = Datos.parsear_repartidor(rep_input)
repartidores = if nuevo_rep, do: Datos.repartidores_defecto() ++ [nuevo_rep], else: Datos.repartidores_defecto()

# 2. Zonas
zona_input = JOptionPane.input_dialog(
  "OPCIONAL: Ingrese una nueva zona (ID;Nombre;Área)\\nEjemplo: Z5;Occidente;15.5\\n\\n(Deje en blanco o Cancele para omitir):",
  "Registro de Zona"
)

nueva_zona = Datos.parsear_zona(zona_input)
zonas = if nueva_zona, do: Datos.zonas_defecto() ++ [nueva_zona], else: Datos.zonas_defecto()

# 3. Servicios Adicionales
serv_input = JOptionPane.input_dialog(
  "OPCIONAL: Ingrese un servicio adicional (repartidor;zona;dia;kilometros;retraso)\\nEjemplo: M03;Z2;4;22.5;-3\\n\\n(Deje en blanco o Cancele para omitir):",
  "Servicio Adicional"
)

servicios_iniciales = Datos.servicios_defecto()

servicios_para_evaluar =
  if serv_input == "" do
    servicios_iniciales
  else
    partes = String.split(serv_input, ";")

    if length(partes) == 5 do
      [rep, zon, str_dia, str_km, str_ret] = partes

      dia_parsed = Integer.parse(str_dia)
      km_parsed = Float.parse(str_km)
      ret_parsed = Float.parse(str_ret)

      if dia_parsed != :error and km_parsed != :error and ret_parsed != :error do
        nuevo_servicio = %{
          repartidor: rep,
          zona: zon,
          dia: elem(dia_parsed, 0),
          kilometros: elem(km_parsed, 0),
          retraso: elem(ret_parsed, 0)
        }
        servicios_iniciales ++ [nuevo_servicio]
      else
        servicios_iniciales
      end
    else
      servicios_iniciales
    end
  end

# ------------------------------------------------------------------------------
# PROCESAMIENTO Y VALIDACIÓN
# ------------------------------------------------------------------------------
resultados_validaciones =
  Enum.map(servicios_para_evaluar, fn s ->
    {s, Liquidacion.validar_servicio(s, repartidores, zonas)}
  end)

servicios_validos =
  resultados_validaciones
  |> Enum.filter(fn {_s, res} -> match?({:ok, _}, res) end)
  |> Enum.map(fn {s, _} -> s end)

servicios_rechazados =
  resultados_validaciones
  |> Enum.filter(fn {_s, res} -> match?({:error, _}, res) end)
  |> Enum.map(fn {s, {:error, motivo}} -> {s, motivo} end)

# ------------------------------------------------------------------------------
# CAPTURA DE SALIDA Y REPORTE EN VENTANA GRÁFICA
# ------------------------------------------------------------------------------
{tiempo_microseg, reporte_capturado} = :timer.tc(fn ->
  capture_io(fn ->
    Liquidacion.reporte_r1(servicios_rechazados)
    Liquidacion.reporte_r2(servicios_validos, zonas)
    mapa_r3 = Liquidacion.reporte_r3(servicios_validos)
    liquidaciones = Liquidacion.reporte_r4(repartidores, servicios_validos)
    Liquidacion.reporte_r5(servicios_validos, repartidores)
    Liquidacion.reporte_r6(servicios_validos)
    Liquidacion.reporte_r7(liquidaciones)
    Liquidacion.reporte_r8(servicios_validos, repartidores, zonas)

    IO.puts("\n=== RANKING (DEMO CON KEYWORD LISTS) ===")
    top3 = Liquidacion.ranking(liquidaciones, por: :neto, orden: :desc, limite: 3)
    Enum.each(top3, fn r -> IO.puts("  Top Repartidor: #{r.nombre} ($#{r.neto})") end)

    IO.puts("\n=== PARTE C: INVESTIGACIÓN MAP.MERGE/3 ===")
    empresa_aliada = %{1 => 580.5, 2 => 430, 3 => 510, 5 => 625, 7 => 180}
    fusion = Liquidacion.investigacion_map_merge(mapa_r3, empresa_aliada)
    IO.puts("  Resultado Fusión de Km (Empresa Propia + Aliada):")
    IO.inspect(fusion)
  end)
end)

final_txt = """
===================================================
    SISTEMA DE LIQUIDACIÓN SEMANAL DE MENSAJERÍA
===================================================

#{reporte_capturado}

---------------------------------------------------
Tiempo total de ejecución: #{tiempo_microseg} microsegundos
---------------------------------------------------
"""

# Muestra la ventana flotante del reporte
JOptionPane.message_dialog(final_txt, "Reporte Final de Liquidacion")

# ------------------------------------------------------------------------------
# CONSULTA DE COMPROBANTE EN VENTANA GRÁFICA
# ------------------------------------------------------------------------------
codigo_input = JOptionPane.input_dialog(
  "Ingrese el código del repartidor para ver su comprobante (ej: M01, M02):\\n\\n(Deje en blanco o Cancele para salir)",
  "Comprobante de Pago"
)

if codigo_input != "" do
  comprobante_txt = capture_io(fn ->
    Liquidacion.comprobante(codigo_input, repartidores, servicios_validos)
  end)

  JOptionPane.message_dialog(comprobante_txt, "Comprobante - #{codigo_input}")
end
