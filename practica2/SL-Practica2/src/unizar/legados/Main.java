package unizar.legados;

public class Main {

    public static void main(String[] args) {

        // Cliente encargado de comunicarse con el mainframe mediante ws3270.
        Ws3270Client client = new Ws3270Client();

        try {
            /*
             * Conexión con el mainframe e inicio de sesión
             * en MUSIC/SP con la cuenta del grupo.
             */
            System.out.println("Conectando...");
            client.connect();

            client.login("grupo_03", "secreto6");
            System.out.println("Login completado.");

            /*
             * Ejecución de la aplicación legada TAREAS.C.
             */
            client.startTasks();
            System.out.println("TAREAS.C iniciado.");

            /*
             * Creación de una tarea general.
             */
            client.assignGeneralTask(
                    "2509",
                    "GeneralJava"
            );
            System.out.println("Tarea general creada correctamente.");

            /*
             * Después de crear una tarea, TAREAS.C vuelve
             * al menú ASSIGN TASKS. Regresamos al menú principal.
             */
            client.backToMainMenu();
            System.out.println("Vuelta al menú principal.");

            /*
             * Creación de una tarea específica.
             */
            client.assignSpecificTask(
                    "2609",
                    "Alejo",
                    "EspecificaJava"
            );
            System.out.println("Tarea específica creada correctamente.");

            /*
             * Volvemos nuevamente al menú principal
             * para dejar TAREAS.C en un estado conocido.
             */
            client.backToMainMenu();
            System.out.println("Vuelta al menú principal.");

            /*
             * Mostramos tares Generales y especificas
             */
            System.out.println("\n--- Recuperando Tareas Generales ---");
            java.util.List<String> generales = client.getGeneralTasks();
            for (String t : generales) {
                System.out.println("Encontrada: " + t);
            }

            System.out.println("\n--- Recuperando Tareas Específicas ---");
            java.util.List<String> especificas = client.getSpecificTasks();
            for (String t : especificas) {
                System.out.println("Encontrada: " + t);
            }

        } catch (Exception e) {

            /*
             * Cualquier error de conexión, navegación o
             * interacción con TAREAS.C se muestra por consola.
             */
            System.err.println(
                    "Error durante la sesión de TAREAS.C:"
            );

            e.printStackTrace();

        } finally {

            /*
             * La conexión con ws3270 se intenta cerrar siempre,
             * incluso si alguna operación anterior produce un error.
             */
            try {
                client.close();
            } catch (Exception e) {
                System.err.println("Error cerrando la conexión:");
                e.printStackTrace();
            }
        }
    }
}