package unizar.legados;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Representa una tarea del sistema legado TAREAS.C.
 * Desacopla las líneas de texto plano del mainframe en un modelo estructurado.
 */
public class Tarea {

    private static final Pattern PATTERN_GENERAL = Pattern.compile(
            "^TASK\\s+(\\d+):\\s+GENERAL\\s+(\\d{4})\\s+-+\\s+(\\S+)",
            Pattern.CASE_INSENSITIVE
    );

    private static final Pattern PATTERN_SPECIFIC = Pattern.compile(
            "^TASK\\s+(\\d+):\\s+SPECIFIC\\s+(\\d{4})\\s+(\\S+)\\s+(\\S+)",
            Pattern.CASE_INSENSITIVE
    );

    private final int id;
    private final String tipo;
    private final String fecha;
    private final String asignadoA;
    private final String descripcion;

    public Tarea(int id, String tipo, String fecha, String asignadoA, String descripcion) {
        this.id = id;
        this.tipo = tipo;
        this.fecha = fecha;
        this.asignadoA = (asignadoA == null || asignadoA.isBlank()) ? "-" : asignadoA;
        this.descripcion = descripcion;
    }

    public int getId() {
        return id;
    }

    public String getTipo() {
        return tipo;
    }

    public String getFecha() {
        return fecha;
    }

    /**
     * Devuelve la fecha formateada en formato legible DD/MM.
     */
    public String getFechaFormateada() {
        if (fecha != null && fecha.length() == 4) {
            return fecha.substring(0, 2) + "/" + fecha.substring(2, 4);
        }
        return fecha;
    }

    public String getAsignadoA() {
        return asignadoA;
    }

    public String getDescripcion() {
        return descripcion;
    }

    /**
     * Devuelve un array de objetos listo para añadirse a un DefaultTableModel.
     */
    public Object[] toTableRow() {
        return new Object[]{
                id,
                tipo,
                getFechaFormateada(),
                asignadoA,
                descripcion
        };
    }

    /**
     * Parsea una línea de salida de TAREAS.C en una instancia de Tarea.
     * Retorna null si la línea no se corresponde con una tarea válida.
     */
    public static Tarea parse(String rawLine) {
        if (rawLine == null) {
            return null;
        }

        String trimmed = rawLine.trim();

        Matcher mGen = PATTERN_GENERAL.matcher(trimmed);
        if (mGen.find()) {
            int id = Integer.parseInt(mGen.group(1));
            String fecha = mGen.group(2);
            String desc = mGen.group(3);
            return new Tarea(id, "General", fecha, "-", desc);
        }

        Matcher mSpec = PATTERN_SPECIFIC.matcher(trimmed);
        if (mSpec.find()) {
            int id = Integer.parseInt(mSpec.group(1));
            String fecha = mSpec.group(2);
            String nombre = mSpec.group(3);
            String desc = mSpec.group(4);
            return new Tarea(id, "Específica", fecha, nombre, desc);
        }

        return null;
    }

    @Override
    public String toString() {
        return "Tarea #" + id + " [" + tipo + "] Fecha: " + getFechaFormateada()
                + " | Asignada a: " + asignadoA + " | " + descripcion;
    }
}
