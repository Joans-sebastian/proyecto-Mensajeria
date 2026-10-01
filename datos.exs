# ==============================================================================
# UNIVERSIDAD DEL QUINDÍO - PROGRAMACIÓN III
# JOAN SEBASTIAN VARGAS
# MÓDULO: Datos
# ==============================================================================

defmodule Datos do
  @moduledoc """
  Módulo que provee colecciones iniciales por defecto y funciones para solicitar
  o ignorar datos dinámicos ingresados por el usuario.
  """

  # Lista base por defecto (en caso de que el cliente decida omitir la creación manual)
  def repartidores_defecto do
    [
      %{codigo: "M01", nombre: "Ana Torres", bicicleta: true},
      %{codigo: "M02", nombre: "David López", bicicleta: false},
      %{codigo: "M03", nombre: "Carlos Ruiz", bicicleta: true},
      %{codigo: "M04", nombre: "Maria Diaz", bicicleta: false},
      %{codigo: "M05", nombre: "Jose Gomez", bicicleta: true},
      %{codigo: "M06", nombre: "Lucia Perez", bicicleta: false},
      %{codigo: "M07", nombre: "Pedro Salinas", bicicleta: true},
      %{codigo: "M08", nombre: "Sofia Castro", bicicleta: false},
      %{codigo: "M09", nombre: "Andres Meza", bicicleta: false},
      %{codigo: "M10", nombre: "Valentina Rios", bicicleta: false}
    ]
  end

  def zonas_defecto do
    [
      %{id: "Z1", nombre: "Centro", area: 6.5},
      %{id: "Z2", nombre: "Norte", area: 10.2},
      %{id: "Z3", nombre: "Sur", area: 8.0},
      %{id: "Z4", nombre: "Este", area: 12.0}
    ]
  end

  def servicios_defecto do
    [
      # --- VÁLIDOS ---
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 30.0, retraso: -5},
      %{repartidor: "M01", zona: "Z2", dia: 1, kilometros: 20.0, retraso: 5},
      %{repartidor: "M01", zona: "Z3", dia: 2, kilometros: 40.0, retraso: 0},
      %{repartidor: "M01", zona: "Z4", dia: 3, kilometros: 15.0, retraso: 10},
      %{repartidor: "M02", zona: "Z2", dia: 1, kilometros: 40.0, retraso: 15},
      %{repartidor: "M02", zona: "Z3", dia: 1, kilometros: 30.0, retraso: 35},
      %{repartidor: "M02", zona: "Z1", dia: 2, kilometros: 25.0, retraso: 0},
      %{repartidor: "M03", zona: "Z4", dia: 3, kilometros: 45.0, retraso: -10},
      %{repartidor: "M03", zona: "Z1", dia: 3, kilometros: 35.0, retraso: 8},
      %{repartidor: "M03", zona: "Z2", dia: 4, kilometros: 20.0, retraso: 2},
      %{repartidor: "M03", zona: "Z3", dia: 5, kilometros: 10.0, retraso: -1},
      %{repartidor: "M04", zona: "Z1", dia: 4, kilometros: 20.0, retraso: 25},
      %{repartidor: "M04", zona: "Z2", dia: 4, kilometros: 25.0, retraso: 12},
      %{repartidor: "M05", zona: "Z3", dia: 5, kilometros: 40.0, retraso: 0},
      %{repartidor: "M05", zona: "Z4", dia: 5, kilometros: 40.0, retraso: -2},
      %{repartidor: "M06", zona: "Z1", dia: 6, kilometros: 10.0, retraso: 5},
      %{repartidor: "M07", zona: "Z2", dia: 2, kilometros: 40.0, retraso: 10},
      %{repartidor: "M08", zona: "Z3", dia: 2, kilometros: 20.0, retraso: 0},
      %{repartidor: "M09", zona: "Z4", dia: 3, kilometros: 15.0, retraso: 10},
      %{repartidor: "M10", zona: "Z1", dia: 4, kilometros: 25.0, retraso: -5},

      # --- INVÁLIDOS ---
      %{repartidor: "M99", zona: "Z1", dia: 1, kilometros: 10.0, retraso: 5},
      %{repartidor: "M88", zona: "Z2", dia: 2, kilometros: 15.0, retraso: 0},
      %{repartidor: "M01", zona: "Z99", dia: 1, kilometros: 10.0, retraso: 5},
      %{repartidor: "M02", zona: "Z88", dia: 3, kilometros: 12.0, retraso: 2},
      %{repartidor: "M01", zona: "Z1", dia: 7, kilometros: 10.0, retraso: 5},
      %{repartidor: "M02", zona: "Z2", dia: 0, kilometros: 15.0, retraso: 10},
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 50.0, retraso: 5},
      %{repartidor: "M02", zona: "Z2", dia: 2, kilometros: -5.0, retraso: 0},
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 10.0, retraso: 200},
      %{repartidor: "M02", zona: "Z2", dia: 3, kilometros: 15.0, retraso: -40}
    ]
  end

  @doc "Parsea una entrada en texto del usuario a un Mapa de Repartidor"
  def parsear_repartidor(cadena) do
    case String.split(cadena, ";") do
      [codigo, nombre, str_bici] ->
        bici = String.downcase(String.trim(str_bici)) in ["true", "si", "sí", "1", "s"]
        %{codigo: String.trim(codigo), nombre: String.trim(nombre), bicicleta: bici}
      _ ->
        nil
    end
  end

  @doc "Transformar una entrada en texto del usuario a un Mapa de Zona"
  def parsear_zona(cadena) do
    case String.split(cadena, ";") do
      [id, nombre, str_area] ->
        case Float.parse(String.trim(str_area)) do
          {area, _} -> %{id: String.trim(id), nombre: String.trim(nombre), area: area}
          :error -> nil
        end
      _ ->
        nil
    end
  end
end
