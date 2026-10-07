package unizar.legados;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

public class Ws3270Client {

    private static final String DEFAULT_WS3270_PATH =
            "C:\\Program Files\\wc3270\\ws3270.exe";

    private static final String MAINFRAME =
            "155.210.152.51:3270";

    private Process process;
    private BufferedWriter writer;
    private BufferedReader reader;

    private boolean connected;
    private long connectionTime;

    /**
     * Localiza el ejecutable de ws3270 priorizando la carpeta actual del programa.
     */
    private String resolveWs3270Path() {
        File localFile = new File("ws3270.exe");
        if (localFile.exists() && localFile.isFile()) {
            return localFile.getAbsolutePath();
        }
        return DEFAULT_WS3270_PATH;
    }

    /**
     * Inicia ws3270 y conecta con el mainframe.
     */
    public void connect() throws IOException {

        ProcessBuilder builder = new ProcessBuilder(
                resolveWs3270Path(),
                MAINFRAME
        );

        builder.redirectErrorStream(true);

        process = builder.start();

        writer = new BufferedWriter(
                new OutputStreamWriter(process.getOutputStream())
        );

        reader = new BufferedReader(
                new InputStreamReader(process.getInputStream())
        );

        connected = true;
        connectionTime = System.currentTimeMillis();

        // Esperamos hasta que la conexión esté en modo 3270.
        executeCommand("Wait(3270Mode)");
    }


    /**
     * Envía un comando a ws3270 y devuelve su respuesta.
     */
    private String executeCommand(String command) throws IOException {

        if (!connected) {
            throw new IOException(
                    "No existe una conexión activa con ws3270"
            );
        }

        writer.write(command);
        writer.newLine();
        writer.flush();

        StringBuilder response = new StringBuilder();
        String line;

        while ((line = reader.readLine()) != null) {

            /*
             * ws3270 termina la respuesta de un comando
             * con "ok" o "error".
             */
            if (line.equals("ok")) {
                return response.toString();
            }

            if (line.equals("error")) {
                throw new IOException(
                        "ws3270 ha rechazado el comando "
                                + command
                                + ":\n"
                                + response
                );
            }

            response.append(line)
                    .append(System.lineSeparator());
        }

        throw new IOException(
                "ws3270 ha cerrado su salida mientras ejecutaba "
                        + command
        );
    }


    /**
     * Obtiene el contenido visible de la pantalla 3270.
     */
    public String getScreen() throws IOException {

        String rawScreen = executeCommand("Ascii()");

        StringBuilder cleanScreen = new StringBuilder();

        for (String line : rawScreen.split("\\R")) {

            if (line.startsWith("data:")) {

                String content = line.substring(5);

                if (content.startsWith(" ")) {
                    content = content.substring(1);
                }

                cleanScreen.append(content)
                        .append(System.lineSeparator());
            }
        }

        return cleanScreen.toString();
    }


    /**
     * Escribe texto en el campo actual asegurando sincronización con el mainframe.
     */
    private void writeText(String text) throws IOException {
        try {
            executeCommand("Wait(Unlock)");
        } catch (Exception ignored) {
        }

        String escapedText = text
                .replace("\\", "\\\\")
                .replace("\"", "\\\"");

        System.out.println("[DEBUG-3270] Escribiendo texto: '" + text + "'");
        executeCommand("String(\"" + escapedText + "\")");
    }

    /**
     * Pulsa ENTER y espera a que el teclado del mainframe se desbloquee.
     */
    private void pressEnter() throws IOException {
        System.out.println("[DEBUG-3270] Pulsando ENTER...");
        executeCommand("Enter()");
        try {
            executeCommand("Wait(Unlock)");
        } catch (Exception ignored) {
        }
        try {
            Thread.sleep(300);
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Devuelve las últimas líneas activas de la consola (omitiendo la barra de estado de Waterloo C).
     */
    public java.util.List<String> getActiveTail() throws IOException {
        String screen = getScreen();
        java.util.List<String> filtered = new java.util.ArrayList<>();
        for (String line : screen.split("\\R")) {
            String stripped = line.trim();
            if (stripped.isEmpty()) {
                continue;
            }
            if (stripped.startsWith("------T") || stripped.equals("Reading") || stripped.equals("More...")) {
                continue;
            }
            filtered.add(stripped);
        }
        int size = filtered.size();
        return size <= 8 ? filtered : filtered.subList(size - 8, size);
    }

    public String getActiveTailString() throws IOException {
        return String.join("\n", getActiveTail());
    }

    /**
     * Espera el siguiente prompt de TAREAS.C consultando la cola activa del terminal.
     * Si detecta que la entrada sigue presente en la línea de comando (debajo de ------T), re-envía ENTER.
     */
    private void waitForPromptAfterEnter(
            String expectedPrompt,
            String operation,
            String submittedInput
    ) throws IOException, InterruptedException {

        long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis() - startTime < 6000) {
            Thread.sleep(200);
            String tail = getActiveTailString();
            String fullScreen = getScreen();

            if (tail.contains(expectedPrompt)) {
                System.out.println("[DEBUG-3270] Prompt encontrado en tail: '" + expectedPrompt + "'");
                return;
            }

            if (fullScreen.contains("More...")) {
                System.out.println("[DEBUG-3270] Detectado 'More...'. Avanzando con ENTER...");
                pressEnter();
                Thread.sleep(300);
                continue;
            }

            // Si el texto introducido sigue presente en la línea de entrada del terminal (debajo de ------T), re-pulsamos ENTER
            if (submittedInput != null && !submittedInput.isEmpty()) {
                String[] lines = fullScreen.split("\\R");
                if (lines.length >= 42 && lines[41].contains(submittedInput)) {
                    System.out.println("[DEBUG-3270] Input '" + submittedInput + "' todavía en línea de entrada. Re-pulsando ENTER...");
                    pressEnter();
                    Thread.sleep(300);
                    continue;
                }
            }
        }

        String fullScreen = getScreen();
        System.err.println("[DEBUG-3270 ERROR] No se encontró prompt '" + expectedPrompt + "' en " + operation);
        throw new IOException(
                "TAREAS.C no ha mostrado " + expectedPrompt
                        + " durante " + operation
                        + ".\nPantalla actual:\n"
                        + fullScreen
        );
    }

    private void waitForPromptAfterEnter(
            String expectedPrompt,
            String operation
    ) throws IOException, InterruptedException {
        waitForPromptAfterEnter(expectedPrompt, operation, null);
    }

    /**
     * Realiza el login en MUSIC/SP.
     */
    public void login(String user, String password)
            throws IOException, InterruptedException {

        Thread.sleep(1000);
        String screen = getScreen();

        if (screen.contains("More...")) {
            pressEnter();
            Thread.sleep(500);
            screen = getScreen();
        }

        if (!screen.contains("MUSIC Userid:")) {
            throw new IOException(
                    "No se ha encontrado la pantalla de login de MUSIC/SP"
            );
        }

        writeText(user);
        executeCommand("Tab()");
        writeText(password);
        pressEnter();

        Thread.sleep(300);
        screen = getScreen();

        if (screen.contains("Userid is in use")) {
            writeText("OK");
            pressEnter();
            Thread.sleep(300);
            screen = getScreen();
        }

        if (screen.contains("Press ENTER to continue")) {
            pressEnter();
            Thread.sleep(300);
        }

        screen = getScreen();
        if (!screen.contains("Command ===>")
                && !screen.contains("Full Screen Interface for MUSIC")) {
            throw new IOException(
                    "No se ha llegado correctamente al menú principal de MUSIC/SP"
            );
        }
    }

    /**
     * Ejecuta TAREAS.C.
     */
    public void startTasks()
            throws IOException, InterruptedException {

        writeText("TAREAS.C");
        pressEnter();
        waitForPromptAfterEnter("MENU PRINCIPAL", "el inicio de TAREAS.C");
    }

    /**
     * Crea una tarea general.
     */
    public void assignGeneralTask(
            String date,
            String description
    ) throws IOException, InterruptedException {

        validateDate(date);
        validateSingleToken(description, "La descripción");

        // MENU PRINCIPAL -> 1 (ASSIGN TASKS)
        writeText("1");
        pressEnter();
        waitForPromptAfterEnter("3. MAIN MENU", "el acceso a ASSIGN TASKS", "1");

        // ASSIGN TASKS -> 1 (GENERAL TASK)
        writeText("1");
        pressEnter();
        waitForPromptAfterEnter("ENTER DATE", "la selección de GENERAL TASK", "1");

        // Fecha
        writeText(date);
        pressEnter();
        waitForPromptAfterEnter("ENTER DESCRIPTION", "la introducción de la fecha", date);

        // Descripción
        writeText(description);
        pressEnter();
        waitForPromptAfterEnter("GENERAL TASK ASSIGNED", "la introducción de la descripción", description);
    }

    /**
     * Crea una tarea específica.
     */
    public void assignSpecificTask(
            String date,
            String name,
            String description
    ) throws IOException, InterruptedException {

        validateDate(date);
        validateSingleToken(name, "El nombre");
        validateSingleToken(description, "La descripción");

        // MENU PRINCIPAL -> 1 (ASSIGN TASKS)
        writeText("1");
        pressEnter();
        waitForPromptAfterEnter("3. MAIN MENU", "el acceso a ASSIGN TASKS", "1");

        // ASSIGN TASKS -> 2 (SPECIFIC TASK)
        writeText("2");
        pressEnter();
        waitForPromptAfterEnter("ENTER DATE", "la selección de SPECIFIC TASK", "2");

        // Fecha
        writeText(date);
        pressEnter();
        waitForPromptAfterEnter("ENTER NAME", "la introducción de la fecha", date);

        // Nombre
        writeText(name);
        pressEnter();
        waitForPromptAfterEnter("ENTER DESCRIPTION", "la introducción del nombre", name);

        // Descripción
        try {
            writeText(description);
            pressEnter();
        } catch (IOException e) {
            throw new IOException(
                    "No se ha podido introducir la descripción de la tarea específica.\nPantalla actual:\n"
                            + getScreen(),
                    e
            );
        }

        waitForPromptAfterEnter("SPECIFIC TASK ASSIGNED", "la introducción de la descripción", description);
    }

    /**
     * Vuelve desde ASSIGN TASKS o VIEW TASKS al menú principal de TAREAS.C.
     */
    public void backToMainMenu()
            throws IOException, InterruptedException {

        System.out.println("[DEBUG-3270] Volviendo al menú principal...");

        for (int i = 0; i < 5; i++) {
            Thread.sleep(300);
            String tail = getActiveTailString();
            String fullScreen = getScreen();

            // Si por cualquier motivo salimos a MUSIC/SP, relanzamos TAREAS.C
            if (fullScreen.contains("Command ===>") || fullScreen.contains("Full Screen Interface for MUSIC")) {
                System.out.println("[DEBUG-3270] Detectado menú MUSIC/SP. Relanzando TAREAS.C...");
                startTasks();
                return;
            }

            // Si ya estamos en el MENU PRINCIPAL activo
            if (tail.contains("3.EXIT") && tail.contains("MENU PRINCIPAL")) {
                System.out.println("[DEBUG-3270] Ya estamos en MENU PRINCIPAL.");
                return;
            }

            // Si estamos en un submenú (ASSIGN TASKS o VIEW TASKS con '3. MAIN MENU' u 'OPTION:')
            if (tail.contains("3. MAIN MENU") || tail.contains("OPTION:")) {
                System.out.println("[DEBUG-3270] En submenú. Enviando '3' para volver a MENU PRINCIPAL...");
                writeText("3");
                pressEnter();
                Thread.sleep(400);

                tail = getActiveTailString();
                if (tail.contains("3.EXIT")) {
                    System.out.println("[DEBUG-3270] Vuelta al menú principal confirmada.");
                    return;
                }
            }

            if (fullScreen.contains("More...")) {
                pressEnter();
            }
        }

        String tail = getActiveTailString();
        if (tail.contains("3.EXIT")) {
            System.out.println("[DEBUG-3270] Vuelta al menú principal confirmada.");
            return;
        }

        throw new IOException("No se ha podido volver al menú principal.\nPantalla actual:\n" + getScreen());
    }

    /**
     * Recupera la lista de tareas generales.
     */
    public java.util.List<String> getGeneralTasks() throws IOException, InterruptedException {
        System.out.println("[DEBUG-3270] Iniciando recuperación de Tareas Generales...");
        java.util.List<String> tasks = new java.util.ArrayList<>();

        // VIEW TASKS
        writeText("2");
        pressEnter();
        waitForPromptAfterEnter("3. MAIN MENU", "el acceso a VIEW TASKS", "2");

        // GENERAL TASKS
        writeText("1");
        pressEnter();

        while (true) {
            Thread.sleep(500);
            String screen = getScreen();

            tasks.addAll(parseTasksFromScreen(screen, "GENERAL"));

            if (screen.contains("More...")) {
                System.out.println("[DEBUG-3270] Más páginas de tareas generales detectadas ('More...'). Pulsando ENTER...");
                pressEnter();
            } else {
                break;
            }
        }

        System.out.println("[DEBUG-3270] Tareas generales leídas: " + tasks.size() + ". Cerrando pantalla de listado...");
        pressEnter();
        Thread.sleep(300);

        backToMainMenu();

        System.out.println("[DEBUG-3270] getGeneralTasks finalizado con éxito.");
        return new java.util.ArrayList<>(new java.util.LinkedHashSet<>(tasks));
    }

    /**
     * Recupera la lista de tareas específicas.
     */
    public java.util.List<String> getSpecificTasks() throws IOException, InterruptedException {
        System.out.println("[DEBUG-3270] Iniciando recuperación de Tareas Específicas...");
        java.util.List<String> tasks = new java.util.ArrayList<>();

        // VIEW TASKS
        writeText("2");
        pressEnter();
        waitForPromptAfterEnter("3. MAIN MENU", "el acceso a VIEW TASKS", "2");

        // SPECIFIC TASKS
        writeText("2");
        pressEnter();

        while (true) {
            Thread.sleep(500);
            String screen = getScreen();

            tasks.addAll(parseTasksFromScreen(screen, "SPECIFIC"));

            if (screen.contains("More...")) {
                System.out.println("[DEBUG-3270] Más páginas de tareas específicas detectadas ('More...'). Pulsando ENTER...");
                pressEnter();
            } else {
                break;
            }
        }

        System.out.println("[DEBUG-3270] Tareas específicas leídas: " + tasks.size() + ". Cerrando pantalla de listado...");
        pressEnter();
        Thread.sleep(300);

        backToMainMenu();

        System.out.println("[DEBUG-3270] getSpecificTasks finalizado con éxito.");
        return new java.util.ArrayList<>(new java.util.LinkedHashSet<>(tasks));
    }

    /**
     * Método auxiliar para extraer las tareas.
     */
    private java.util.List<String> parseTasksFromScreen(String screen, String type) {
        java.util.List<String> extracted = new java.util.ArrayList<>();
        String[] lines = screen.split("\\R");
        
        for (String line : screen.split("\\R")) {
            String trimmed = line.trim();
            if (trimmed.matches("^TASK \\d+: " + type + ".*")) {
                extracted.add(trimmed);
            }
        }
        return extracted;
    }

    /**
     * Valida una fecha con formato DDMM.
     */
    private void validateDate(String date) {

        if (date == null || !date.matches("\\d{4}")) {

            throw new IllegalArgumentException(
                    "La fecha debe tener formato DDMM"
            );
        }

        int day = Integer.parseInt(
                date.substring(0, 2)
        );

        int month = Integer.parseInt(
                date.substring(2, 4)
        );

        if (day < 1 || day > 31
                || month < 1 || month > 12) {

            throw new IllegalArgumentException(
                    "La fecha DDMM no es válida"
            );
        }
    }

    /**
     * TAREAS.C divide estos campos por espacios; cada valor debe ser un token.
     * Además no puede contener mas de 20 caracteres (evitar buffer overflow)
     */
    private void validateSingleToken(String value, String fieldName) {
    	if (value == null || value.isBlank() || value.matches(".*\\s+.*")) {
            throw new IllegalArgumentException(fieldName + " debe contener un único texto sin espacios");
        }
        if (value.length() > 20) {
            throw new IllegalArgumentException(fieldName + " supera el límite de 20 caracteres del Mainframe");
        }
    }


    /**
     * Cierra ws3270 respetando la restricción
     * de al menos un segundo entre conexión
     * y desconexión.
     */
    public void close()
            throws IOException, InterruptedException {

        if (!connected) {
            return;
        }

        long elapsed =
                System.currentTimeMillis()
                        - connectionTime;

        if (elapsed < 1000) {

            Thread.sleep(
                    1000 - elapsed
            );
        }

        writer.write("Quit()");
        writer.newLine();
        writer.flush();

        process.waitFor();

        connected = false;
    }
}
