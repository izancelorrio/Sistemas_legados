package unizar.legados;

import javax.swing.*;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.List;

public class AppGUI extends JFrame {

    private Ws3270Client client;
    private JTextArea consoleArea;
    private JButton btnConnect, btnGeneral, btnSpecific, btnViewGeneral, btnViewSpecific, btnExit;
    private boolean isConnectedToMainframe = false;

    public AppGUI() {
        client = new Ws3270Client();

        setTitle("Gestor de Tareas Legado - MUSIC/SP");
        setSize(750, 500);
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE); 
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        consoleArea = new JTextArea();
        consoleArea.setEditable(false);
        consoleArea.setFont(new Font("Monospaced", Font.PLAIN, 14));
        consoleArea.setBackground(new Color(10, 10, 10));
        consoleArea.setForeground(new Color(0, 255, 0)); 
        
        JScrollPane scrollPane = new JScrollPane(consoleArea);
        scrollPane.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(Color.GRAY), 
                "Terminal de Salida", 
                0, 0, null, Color.WHITE));
        
        JPanel centerPanel = new JPanel(new BorderLayout());
        centerPanel.setBackground(Color.DARK_GRAY);
        centerPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        centerPanel.add(scrollPane, BorderLayout.CENTER);
        add(centerPanel, BorderLayout.CENTER);

        JPanel buttonPanel = new JPanel(new GridLayout(2, 3, 10, 10));
        buttonPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        btnConnect = new JButton("Conectar al servidor");
        btnGeneral = new JButton("Nueva Tarea General");
        btnSpecific = new JButton("Nueva Tarea Específica");
        btnViewGeneral = new JButton("Ver Tareas Generales");
        btnViewSpecific = new JButton("Ver Tareas Específicas");
        btnExit = new JButton("Salir");

        buttonPanel.add(btnConnect);
        buttonPanel.add(btnGeneral);
        buttonPanel.add(btnSpecific);
        buttonPanel.add(btnExit); 
        buttonPanel.add(btnViewGeneral);
        buttonPanel.add(btnViewSpecific);

        add(buttonPanel, BorderLayout.SOUTH);

        setAppState(false, false);
        setupActions();

        // Bloqueamos X
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                safeDisconnectAndExit();
            }
        });
    }

    private void log(String message) {
        SwingUtilities.invokeLater(() -> {
            consoleArea.append(message + "\n");
            consoleArea.setCaretPosition(consoleArea.getDocument().getLength());
        });
    }

    private void setAppState(boolean connected, boolean isProcessing) {
        this.isConnectedToMainframe = connected;
        
        if (isProcessing) {
            btnConnect.setEnabled(false);
            btnGeneral.setEnabled(false);
            btnSpecific.setEnabled(false);
            btnViewGeneral.setEnabled(false);
            btnViewSpecific.setEnabled(false);
            btnExit.setEnabled(false);
        } else {
            btnConnect.setEnabled(!connected);
            btnGeneral.setEnabled(connected);
            btnSpecific.setEnabled(connected);
            btnViewGeneral.setEnabled(connected);
            btnViewSpecific.setEnabled(connected);
            btnExit.setEnabled(true);
        }
    }

    // --- Validación de datos ---
    private boolean isInvalidDate(String date) {
        if (date == null) return true; 
        if (!date.matches("\\d{4}")) {
            JOptionPane.showMessageDialog(this, "Error: La fecha debe tener 4 dígitos (DDMM).", "Validación", JOptionPane.ERROR_MESSAGE);
            return true;
        }
        return false;
    }

    private boolean isInvalidText(String text, String fieldName) {
        if (text == null) return true; 
        if (text.contains(" ")) {
            JOptionPane.showMessageDialog(this, "Error: " + fieldName + " sin espacios.", "Validación", JOptionPane.ERROR_MESSAGE);
            return true;
        }
        if (text.length() > 20) {
            JOptionPane.showMessageDialog(this, "Error: " + fieldName + " máx 20 caracteres.", "Validación", JOptionPane.ERROR_MESSAGE);
            return true;
        }
        if (text.trim().isEmpty()) return true;
        return false;
    }

    private void safeDisconnectAndExit() {
        log("Iniciando protocolo de desconexión segura...");
        setAppState(false, true); 
        
        new Thread(() -> {
            try {
                client.close();
            } catch (Exception ex) {
                log("Aviso al cerrar: " + ex.getMessage());
            }
            
            try {
                Thread.sleep(1500); 
            } catch (InterruptedException ignored) {}
            
            log("Desconectado. Cerrando programa...");
            System.exit(0); 
        }).start();
    }

    private void setupActions() {
        btnConnect.addActionListener(e -> {
            log("Iniciando conexión");
            setAppState(false, true); 
            new Thread(() -> {
                try {
                    client.connect();
                    client.login("grupo_03", "secreto6");
                    client.startTasks();
                    log("¡Conexión exitosa! El mainframe está listo para recibir órdenes.");
                    SwingUtilities.invokeLater(() -> setAppState(true, false)); 
                } catch (Exception ex) {
                    log("ERROR de conexión: " + ex.getMessage());
                    SwingUtilities.invokeLater(() -> setAppState(false, false));
                }
            }).start();
        });

        btnExit.addActionListener(e -> safeDisconnectAndExit());

        btnGeneral.addActionListener(e -> {
            String date = JOptionPane.showInputDialog(this, "Introduce fecha (DDMM):");
            if (isInvalidDate(date)) return;
            String desc = JOptionPane.showInputDialog(this, "Introduce descripción (Máx 20, sin espacios):");
            if (isInvalidText(desc, "La descripción")) return;

            log("Enviando Tarea General al servidor...");
            setAppState(true, true); 
            new Thread(() -> {
                try {
                    client.assignGeneralTask(date, desc);
                    client.backToMainMenu();
                    log("--> Tarea General '" + desc + "' asignada.");
                } catch (Exception ex) { 
                    log("ERROR: " + ex.getMessage());
                    try { client.backToMainMenu(); } catch (Exception ignored) {}
                } finally { SwingUtilities.invokeLater(() -> setAppState(true, false)); }
            }).start();
        });

        btnSpecific.addActionListener(e -> {
            String date = JOptionPane.showInputDialog(this, "Introduce fecha (DDMM):");
            if (isInvalidDate(date)) return;
            String name = JOptionPane.showInputDialog(this, "Introduce nombre (Máx 20, sin espacios):");
            if (isInvalidText(name, "El nombre")) return;
            String desc = JOptionPane.showInputDialog(this, "Introduce descripción (Máx 20, sin espacios):");
            if (isInvalidText(desc, "La descripción")) return;

            log("Enviando Tarea Específica al servidor...");
            setAppState(true, true); 
            new Thread(() -> {
                try {
                    client.assignSpecificTask(date, name, desc);
                    client.backToMainMenu();
                    log("--> Tarea Específica '" + desc + "' asignada a " + name + ".");
                } catch (Exception ex) { 
                    log("ERROR: " + ex.getMessage());
                    try { client.backToMainMenu(); } catch (Exception ignored) {}
                } finally { SwingUtilities.invokeLater(() -> setAppState(true, false)); }
            }).start();
        });

        btnViewGeneral.addActionListener(e -> {
            log("\nRecuperando Tareas Generales...");
            setAppState(true, true); 
            new Thread(() -> {
                try {
                    List<String> tasks = client.getGeneralTasks();
                    for (String t : tasks) log(t);
                    log("--- Fin de la lista (" + tasks.size() + " encontradas) ---");
                } catch (Exception ex) { log("ERROR: " + ex.getMessage());
                } finally { SwingUtilities.invokeLater(() -> setAppState(true, false)); }
            }).start();
        });

        btnViewSpecific.addActionListener(e -> {
            log("\nRecuperando Tareas Específicas...");
            setAppState(true, true); 
            new Thread(() -> {
                try {
                    List<String> tasks = client.getSpecificTasks();
                    for (String t : tasks) log(t);
                    log("--- Fin de la lista (" + tasks.size() + " encontradas) ---");
                } catch (Exception ex) { log("ERROR: " + ex.getMessage());
                } finally { SwingUtilities.invokeLater(() -> setAppState(true, false)); }
            }).start();
        });
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new AppGUI().setVisible(true));
    }
}