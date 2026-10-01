# ==============================================================================
# UNIVERSIDAD DEL QUINDÍO - PROGRAMACIÓN III
# JOAN SEBASTIAN VARGAS
# MÓDULO: Liquidacion
# ==============================================================================

defmodule Liquidacion do
  @moduledoc """
  Contiene la lógica de negocio, cálculos financieros y la generación de reportes.
  """

  @tarifa_base 2500
  @meta_diaria 500
  @dias_operacion 1..6
  @max_kilometros 45
  @km_bonificacion 80
  @monto_bonificacion 15000
  @monto_bicicleta 10000

  # ============================================================================
  # 1. VALIDACIÓN DE SERVICIOS
  # ============================================================================

  def validar_servicio(servicio, repartidores, zonas) do
    codigos_repartidores = Enum.map(repartidores, & &1.codigo)
    ids_zonas = Enum.map(zonas, & &1.id)

    with true <- servicio.repartidor in codigos_repartidores,
         true <- servicio.zona in ids_zonas,
         true <- is_integer(servicio.dia) and servicio.dia in @dias_operacion,
         true <- is_number(servicio.kilometros) and servicio.kilometros > 0 and servicio.kilometros <= @max_kilometros,
         true <- is_number(servicio.retraso) and servicio.retraso >= -30 and servicio.retraso <= 180 do
      {:ok, servicio}
    else
      _ -> {:error, obtener_motivo_error(servicio, codigos_repartidores, ids_zonas)}
    end
  end

  defp obtener_motivo_error(servicio, codigos_repartidores, ids_zonas) do
    cond do
      servicio.repartidor not in codigos_repartidores -> :repartidor_desconocido
      servicio.zona not in ids_zonas -> :zona_desconocida
      not (is_integer(servicio.dia) and servicio.dia in @dias_operacion) -> :dia_invalido
      not (is_number(servicio.kilometros) and servicio.kilometros > 0 and servicio.kilometros <= @max_kilometros) -> :kilometros_fuera_de_rango
      not (is_number(servicio.retraso) and servicio.retraso >= -30 and servicio.retraso <= 180) -> :retraso_invalido
      true -> :error_desconocido
    end
  end

  # ============================================================================
  # 2. CÁLCULO DE COSTOS Y VALORES
  # ============================================================================

  def valor_servicio(%{kilometros: km, retraso: retraso}) do
    valor_base = km * @tarifa_base
    ajuste = calcular_ajuste_puntualidad(valor_base, retraso)
    valor_base + ajuste
  end

  defp calcular_ajuste_puntualidad(valor_base, retraso) do
    cond do
      retraso <= 0 -> valor_base * 0.08
      retraso <= 10 -> 0.0
      retraso <= 30 -> valor_base * -0.10
      true -> valor_base * -0.25
    end
  end

  def bonificacion_dia(km_total_dia) do
    if km_total_dia >= @km_bonificacion, do: @monto_bonificacion, else: 0
  end

  def alquiler_bicicleta(usa_bicicleta, cantidad_dias_trabajados) do
    if usa_bicicleta, do: cantidad_dias_trabajados * @monto_bicicleta, else: 0
  end

  # ============================================================================
  # 3. REPORTES (R1 a R8)
  # ============================================================================

  def reporte_r1(servicios_rechazados) do
    IO.puts("\n=== R1: SERVICIOS RECHAZADOS ===")
    Enum.each(servicios_rechazados, fn {serv, motivo} ->
      IO.puts("  -> Rep: #{serv.repartidor} | Zona: #{serv.zona} | Día: #{serv.dia} | Motivo: #{motivo}")
    end)

    conteos =
      servicios_rechazados
      |> Enum.group_by(fn {_serv, motivo} -> motivo end)
      |> Enum.map(fn {motivo, lista} -> {motivo, length(lista)} end)

    IO.puts("\n  Totales por motivo de rechazo:")
    Enum.each(conteos, fn {motivo, cant} ->
      IO.puts("     * #{motivo}: #{cant}")
    end)
  end

  def reporte_r2(servicios_validos, zonas) do
    IO.puts("\n=== R2: KILÓMETROS POR ZONA Y DENSIDAD ===")
    km_por_zona = Enum.group_by(servicios_validos, & &1.zona, & &1.kilometros)

    zonas_calculadas =
      Enum.map(zonas, fn zona ->
        kms = Map.get(km_por_zona, zona.id, [])
        km_total = Enum.sum(kms)
        densidad = if zona.area > 0, do: km_total / zona.area, else: 0.0
        %{nombre: zona.nombre, km_total: km_total, densidad: densidad}
      end)
      |> Enum.sort_by(& &1.densidad, :desc)

    Enum.each(zonas_calculadas, fn z ->
      IO.puts("  -> #{z.nombre}: #{z.km_total} km | Densidad: #{Float.round(z.densidad, 2)} km/km²")
    end)
  end

  def reporte_r3(servicios_validos) do
    IO.puts("\n=== R3: KILÓMETROS DIARIOS DE LA EMPRESA Y META ===")
    km_por_dia = Enum.group_by(servicios_validos, & &1.dia, & &1.kilometros)

    dias_evaluados =
      Enum.map(@dias_operacion, fn dia ->
        kms = Map.get(km_por_dia, dia, [])
        total_km = Enum.sum(kms)
        alcanzo? = total_km >= @meta_diaria
        {dia, total_km, alcanzo?}
      end)

    Enum.each(dias_evaluados, fn {dia, km, alcanzo?} ->
      estado = if alcanzo?, do: "ALCANZADA", else: "NO ALCANZADA"
      IO.puts("  -> Día #{dia}: #{km} km | Meta (#{@meta_diaria} km): #{estado}")
    end)

    todos? = Enum.all?(dias_evaluados, fn {_d, _km, a} -> a end)
    al_menos_uno? = Enum.any?(dias_evaluados, fn {_d, _km, a} -> a end)

    IO.puts("\n  ¿Se alcanzó la meta TODOS los días?: #{if todos?, do: "SÍ", else: "NO"}")
    IO.puts("  ¿Se alcanzó la meta AL MENOS UN día?: #{if al_menos_uno?, do: "SÍ", else: "NO"}")

    Map.new(dias_evaluados, fn {d, km, _} -> {d, km} end)
  end

  def reporte_r4(repartidores, servicios_validos) do
    IO.puts("\n=== R4: LIQUIDACIÓN SEMANAL DE REPARTIDORES ===")

    liquidaciones =
      Enum.map(repartidores, fn rep ->
        servs_rep = Enum.filter(servicios_validos, &(&1.repartidor == rep.codigo))
        valor_servs = Enum.sum(Enum.map(servs_rep, &valor_servicio/1))
        km_totales = Enum.sum(Enum.map(servs_rep, & &1.kilometros))

        por_dia = Enum.group_by(servs_rep, & &1.dia)
        dias_trabajados = Map.keys(por_dia)

        bonificaciones =
          Enum.sum(
            Enum.map(dias_trabajados, fn d ->
              km_dia = Enum.sum(Enum.map(por_dia[d], & &1.kilometros))
              bonificacion_dia(km_dia)
            end)
          )

        alquiler = alquiler_bicicleta(rep.bicicleta, length(dias_trabajados))
        neto = valor_servs + bonificaciones - alquiler

        %{
          codigo: rep.codigo,
          nombre: rep.nombre,
          km_totales: km_totales,
          valor_servicios: valor_servs,
          bonificaciones: bonificaciones,
          alquiler: alquiler,
          neto: neto
        }
      end)
      |> Enum.sort_by(& &1.neto, :desc)

    Enum.with_index(liquidaciones, 1)
    |> Enum.each(fn {l, idx} ->
      IO.puts("  #{idx}. [#{l.codigo}] #{l.nombre} | Km: #{l.km_totales} | Serv: $#{l.valor_servicios} | Bonif: $#{l.bonificaciones} | Alq: -$#{l.alquiler} | NETO: $#{l.neto}")
    end)

    liquidaciones
  end

  def reporte_r5(servicios_validos, repartidores) do
    IO.puts("\n=== R5: MEJOR REPARTIDOR POR DÍA ===")
    nombres_map = Map.new(repartidores, fn r -> {r.codigo, r.nombre} end)

    mejores_por_dia =
      Enum.map(@dias_operacion, fn dia ->
        servs_dia = Enum.filter(servicios_validos, &(&1.dia == dia))
        totales_rep = Enum.group_by(servs_dia, & &1.repartidor, & &1.kilometros)
                      |> Enum.map(fn {rep, kms} -> {rep, Enum.sum(kms)} end)

        if Enum.empty?(totales_rep) do
          {dia, [], 0}
        else
          max_km = Enum.max_by(totales_rep, &elem(&1, 1)) |> elem(1)
          ganadores = Enum.filter(totales_rep, fn {_r, km} -> km == max_km end) |> Enum.map(&elem(&1, 0))
          {dia, ganadores, max_km}
        end
      end)

    Enum.each(mejores_por_dia, fn {dia, ganadores, km} ->
      nombres = Enum.map(ganadores, &Map.get(nombres_map, &1, &1)) |> Enum.join(", ")
      if km > 0 do
        IO.puts("  -> Día #{dia}: #{nombres} (#{km} km)")
      else
        IO.puts("  -> Día #{dia}: Sin entregas registradas")
      end
    end)

    ganadores_globales =
      mejores_por_dia
      |> Enum.flat_map(fn {_d, g, _km} -> g end)
      |> Enum.frequencies()

    if not Enum.empty?(ganadores_globales) do
      max_victorias = Enum.max_by(ganadores_globales, &elem(&1, 1)) |> elem(1)
      campeones = Enum.filter(ganadores_globales, fn {_r, cant} -> cant == max_victorias end)
                  |> Enum.map(fn {r, _} -> Map.get(nombres_map, r, r) end)
                  |> Enum.join(", ")

      IO.puts("\n  Ganador(es) con más días en 1er lugar (#{max_victorias} días): #{campeones}")
    end
  end

  def reporte_r6(servicios_validos) do
    IO.puts("\n=== R6: MEJOR PUNTUALIDAD PONDERADA (>= 3 SERVICIOS) ===")
    por_repartidor = Enum.group_by(servicios_validos, & &1.repartidor)

    promedios_ponderados =
      Enum.map(por_repartidor, fn {rep, servs} ->
        if length(servs) >= 3 do
          suma_producto = Enum.sum(Enum.map(servs, fn s -> s.retraso * s.kilometros end))
          suma_km = Enum.sum(Enum.map(servs, & &1.kilometros))
          promedio = if suma_km > 0, do: suma_producto / suma_km, else: 0
          {rep, promedio}
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if not Enum.empty?(promedios_ponderados) do
      {mejor_rep, mejor_valor} = Enum.min_by(promedios_ponderados, &elem(&1, 1))
      IO.puts("  -> Repartidor más puntual: #{mejor_rep} con un retraso promedio ponderado de #{Float.round(mejor_valor, 2)} min")
    else
      IO.puts("  -> Ningún repartidor cumple con el mínimo de 3 servicios válidos.")
    end
  end

  def reporte_r7(liquidaciones) do
    IO.puts("\n=== R7: TOTALES GENERALES DE LA SEMANA ===")
    total_pagado = Enum.sum(Enum.map(liquidaciones, & &1.neto))
    total_km = Enum.sum(Enum.map(liquidaciones, & &1.km_totales))
    costo_promedio_km = if total_km > 0, do: total_pagado / total_km, else: 0.0

    IO.puts("  -> Total pagado a repartidores: $#{total_pagado}")
    IO.puts("  -> Total kilómetros recorridos: #{total_km} km")
    IO.puts("  -> Costo promedio por kilómetro: $#{Float.round(costo_promedio_km, 2)}")
  end

  def reporte_r8(servicios_validos, repartidores, zonas) do
    IO.puts("\n=== R8: REPARTIDORES EN TODAS LAS ZONAS ===")
    todos_ids_zonas = MapSet.new(Enum.map(zonas, & &1.id))

    cumplen =
      Enum.filter(repartidores, fn rep ->
        zonas_visitadas =
          servicios_validos
          |> Enum.filter(&(&1.repartidor == rep.codigo))
          |> Enum.map(& &1.zona)
          |> MapSet.new()

        MapSet.subset?(todos_ids_zonas, zonas_visitadas)
      end)

    if not Enum.empty?(cumplen) do
      Enum.each(cumplen, fn r -> IO.puts("  -> [#{r.codigo}] #{r.nombre}") end)
    else
      IO.puts("  -> Ningún repartidor visitó todas las zonas durante la semana.")
    end
  end

  def ranking(liquidaciones, opts \\ []) do
    por = Keyword.get(opts, :por, :neto)
    orden = Keyword.get(opts, :orden, :desc)
    limite = Keyword.get(opts, :limite, length(liquidaciones))

    liquidaciones
    |> Enum.sort_by(fn item -> Map.get(item, por, 0) end, orden)
    |> Enum.take(limite)
  end

  def comprobante(codigo_rep, repartidores, servicios_validos) do
    rep = Enum.find(repartidores, &(&1.codigo == codigo_rep))

    if is_nil(rep) do
      IO.puts("\nError: El código de repartidor '#{codigo_rep}' no existe.")
    else
      servs_rep = Enum.filter(servicios_validos, &(&1.repartidor == rep.codigo))
      por_dia = Enum.group_by(servs_rep, & &1.dia)

      IO.puts("\n========================================")
      IO.puts("         COMPROBANTE DE PAGO            ")
      IO.puts("========================================")
      IO.puts("Repartidor: #{rep.nombre} (#{rep.codigo})")
      IO.puts("Usa Bicicleta Eléctrica: #{if rep.bicicleta, do: "SÍ", else: "NO"}")
      IO.puts("----------------------------------------")

      dias_trabajados = Map.keys(por_dia) |> Enum.sort()

      {total_servicios, total_bonif} =
        Enum.reduce(dias_trabajados, {0.0, 0}, fn d, {acc_s, acc_b} ->
          servs = por_dia[d]
          km_dia = Enum.sum(Enum.map(servs, & &1.kilometros))
          val_dia = Enum.sum(Enum.map(servs, &valor_servicio/1))
          bonif_dia = bonificacion_dia(km_dia)

          IO.puts("  Día #{d}: #{km_dia} km | Servicios: $#{val_dia} | Bonif: $#{bonif_dia}")
          {acc_s + val_dia, acc_b + bonif_dia}
        end)

      alquiler = alquiler_bicicleta(rep.bicicleta, length(dias_trabajados))
      neto = total_servicios + total_bonif - alquiler

      IO.puts("----------------------------------------")
      IO.puts("  (+) Suma Valor Servicios:    $#{total_servicios}")
      IO.puts("  (+) Suma Bonificaciones:    $#{total_bonif}")
      IO.puts("  (-) Alquiler de Bicicleta:  -$#{alquiler}")
      IO.puts("  --------------------------------------")
      IO.puts("  (=) NETO A PAGAR:            $#{neto}")
      IO.puts("========================================\n")
    end
  end

  def investigacion_map_merge(mapa_r3, empresa_aliada) do
    Map.merge(mapa_r3, empresa_aliada, fn _dia, km_propio, km_aliado ->
      km_propio + km_aliado
    end)
  end
end
