package unizar.legados;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.TitledBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.JTableHeader;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Interfaz Gráfica de Usuario moderna para la gestión de tareas legadas (TAREAS.C)
 * en el mainframe IBM ESA/390 (MUSIC/SP).
 */
public class AppGUI extends JFrame {

    private final Ws3270Client client;
    private boolean isConnectedToMainframe = false;

    // Componentes del formulario superior
    private JRadioButton rbGeneral;
    private JRadioButton rbSpecific;
    private JTextField txtDate;
    private JTextField txtName;
    private JTextField txtDesc;
    private JButton btnAdd;

    // Componentes de la tabla central
    private DefaultTableModel tableModel;
    private JTable table;

    // Botones de acción laterales
    private JButton btnConnect;
    private JButton btnRefresh;
    private JButton btnExit;

    // Barra de estado inferior
    private JLabel lblStatus;
    private JLabel lblCount;

    public AppGUI() {
        client = new Ws3270Client();

        // Aplicar aspecto visual del sistema operativo
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) {
        }

        initWindow();
        initComponents();
        setupEvents();
        updateAppState(false, false);
    }

    private void initWindow() {
        setTitle("Gestor de Tareas - Mainframe IBM ESA/390");
        setSize(880, 560);
        setMinimumSize(new Dimension(750, 480));
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(10, 10));

        // Padding general de la ventana
        ((JComponent) getContentPane()).setBorder(new EmptyBorder(12, 12, 8, 12));

        // Intercepción del cierre de ventana para desconexión limpia
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                safeDisconnectAndExit();
            }
        });
    }

    private void initComponents() {
        // 1. Panel superior: Formulario de Nueva Tarea
        add(createFormPanel(), BorderLayout.NORTH);

        // 2. Panel central: Tabla de tareas estructurada
        add(createTablePanel(), BorderLayout.CENTER);

        // 3. Panel lateral derecho: Botones de control
        add(createSidePanel(), BorderLayout.EAST);

        // 4. Panel inferior: Barra de estado
        add(createStatusBar(), BorderLayout.SOUTH);
    }

    /**
     * Construye el panel superior con el formulario para registrar nuevas tareas.
     */
    private JPanel createFormPanel() {
        JPanel formPanel = new JPanel(new GridBagLayout());
        formPanel.setBorder(new CompoundBorder(
                BorderFactory.createTitledBorder(
                        BorderFactory.createEtchedBorder(),
                        "Nueva Tarea",
                        TitledBorder.LEFT,
                        TitledBorder.TOP,
                        new Font("SansSerif", Font.BOLD, 12)
                ),
                new EmptyBorder(6, 10, 8, 10)
        ));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(4, 6, 4, 6);
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.gridy = 0;

        // Selector de tipo (General / Específica)
        rbGeneral = new JRadioButton("General", true);
        rbSpecific = new JRadioButton("Específica");
        ButtonGroup bg = new ButtonGroup();
        bg.add(rbGeneral);
        bg.add(rbSpecific);

        JPanel typePanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 4, 0));
        typePanel.add(new JLabel("Tipo:"));
        typePanel.add(rbGeneral);
        typePanel.add(rbSpecific);

        gbc.gridx = 0;
        gbc.weightx = 0;
        formPanel.add(typePanel, gbc);

        // Campo Fecha (DDMM)
        JPanel datePanel = new JPanel(new BorderLayout(4, 0));
        datePanel.add(new JLabel("Fecha (DDMM):"), BorderLayout.NORTH);
        txtDate = new JTextField(6);
        txtDate.setToolTipText("Ejemplo: 2509 (25 de septiembre)");
        datePanel.add(txtDate, BorderLayout.CENTER);

        gbc.gridx = 1;
        gbc.weightx = 0.15;
        formPanel.add(datePanel, gbc);

        // Campo Nombre (Asignado a)
        JPanel namePanel = new JPanel(new BorderLayout(4, 0));
        namePanel.add(new JLabel("Asignado a:"), BorderLayout.NORTH);
        txtName = new JTextField(12);
        txtName.setEnabled(false); // Inicia deshabilitado porque 'General' está marcado por defecto
        txtName.setToolTipText("Nombre de la persona (máx 20 caracteres, sin espacios)");
        namePanel.add(txtName, BorderLayout.CENTER);

        gbc.gridx = 2;
        gbc.weightx = 0.25;
        formPanel.add(namePanel, gbc);

        // Campo Descripción
        JPanel descPanel = new JPanel(new BorderLayout(4, 0));
        descPanel.add(new JLabel("Descripción:"), BorderLayout.NORTH);
        txtDesc = new JTextField(18);
        txtDesc.setToolTipText("Descripción de la tarea (máx 20 caracteres, sin espacios)");
        descPanel.add(txtDesc, BorderLayout.CENTER);

        gbc.gridx = 3;
        gbc.weightx = 0.40;
        formPanel.add(descPanel, gbc);

        // Botón Añadir Tarea
        btnAdd = new JButton("Añadir Tarea");
        btnAdd.setFont(new Font("SansSerif", Font.BOLD, 12));
        gbc.gridx = 4;
        gbc.weightx = 0.1;
        gbc.fill = GridBagConstraints.NONE;
        gbc.anchor = GridBagConstraints.SOUTH;
        formPanel.add(btnAdd, gbc);

        return formPanel;
    }

    /**
     * Construye el panel central con la tabla JTable y su scroll.
     */
    private JPanel createTablePanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(new CompoundBorder(
                BorderFactory.createTitledBorder(
                        BorderFactory.createEtchedBorder(),
                        "Listado de Tareas (Mainframe)",
                        TitledBorder.LEFT,
                        TitledBorder.TOP,
                        new Font("SansSerif", Font.BOLD, 12)
                ),
                new EmptyBorder(4, 6, 6, 6)
        ));

        String[] columns = {"Nº", "Tipo", "Fecha", "Asignado a", "Descripción"};
        tableModel = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // Tabla de solo lectura
            }
        };

        table = new JTable(tableModel);
        table.setFillsViewportHeight(true);
        table.setRowHeight(24);
        table.setFont(new Font("SansSerif", Font.PLAIN, 12));
        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        table.setShowGrid(true);
        table.setGridColor(new Color(230, 230, 230));

        // Estilo de la cabecera
        JTableHeader header = table.getTableHeader();
        header.setFont(new Font("SansSerif", Font.BOLD, 12));
        header.setReorderingAllowed(false);

        // Ajuste del ancho y alineación de columnas
        DefaultTableCellRenderer centerRenderer = new DefaultTableCellRenderer();
        centerRenderer.setHorizontalAlignment(SwingConstants.CENTER);

        table.getColumnModel().getColumn(0).setPreferredWidth(45);
        table.getColumnModel().getColumn(0).setMaxWidth(60);
        table.getColumnModel().getColumn(0).setCellRenderer(centerRenderer);

        table.getColumnModel().getColumn(1).setPreferredWidth(95);
        table.getColumnModel().getColumn(1).setMaxWidth(120);
        table.getColumnModel().getColumn(1).setCellRenderer(centerRenderer);

        table.getColumnModel().getColumn(2).setPreferredWidth(75);
        table.getColumnModel().getColumn(2).setMaxWidth(90);
        table.getColumnModel().getColumn(2).setCellRenderer(centerRenderer);

        table.getColumnModel().getColumn(3).setPreferredWidth(140);
        table.getColumnModel().getColumn(4).setPreferredWidth(280);

        JScrollPane scrollPane = new JScrollPane(table);
        panel.add(scrollPane, BorderLayout.CENTER);

        return panel;
    }

    /**
     * Construye el panel lateral derecho con los botones de acción principales.
     */
    private JPanel createSidePanel() {
        JPanel sidePanel = new JPanel();
        sidePanel.setLayout(new BoxLayout(sidePanel, BoxLayout.Y_AXIS));
        sidePanel.setBorder(new EmptyBorder(10, 4, 10, 0));

        btnConnect = new JButton("Conectar");
        btnConnect.setMaximumSize(new Dimension(130, 36));
        btnConnect.setPreferredSize(new Dimension(130, 36));

        btnRefresh = new JButton("Recargar");
        btnRefresh.setMaximumSize(new Dimension(130, 36));
        btnRefresh.setPreferredSize(new Dimension(130, 36));

        btnExit = new JButton("Salir");
        btnExit.setMaximumSize(new Dimension(130, 36));
        btnExit.setPreferredSize(new Dimension(130, 36));

        sidePanel.add(btnConnect);
        sidePanel.add(Box.createVerticalStrut(10));
        sidePanel.add(btnRefresh);
        sidePanel.add(Box.createVerticalGlue());
        sidePanel.add(btnExit);

        return sidePanel;
    }

    /**
     * Construye la barra de estado inferior.
     */
    private JPanel createStatusBar() {
        JPanel statusBar = new JPanel(new BorderLayout(10, 0));
        statusBar.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(1, 0, 0, 0, Color.LIGHT_GRAY),
                new EmptyBorder(5, 5, 2, 5)
        ));

        lblStatus = new JLabel("● Desconectado");
        lblStatus.setFont(new Font("SansSerif", Font.PLAIN, 12));
        lblStatus.setForeground(Color.DARK_GRAY);

        lblCount = new JLabel("Tareas: 0");
        lblCount.setFont(new Font("SansSerif", Font.PLAIN, 12));
        lblCount.setForeground(Color.DARK_GRAY);

        statusBar.add(lblStatus, BorderLayout.WEST);
        statusBar.add(lblCount, BorderLayout.EAST);

        return statusBar;
    }

    /**
     * Configuración de oyentes y eventos de usuario.
     */
    private void setupEvents() {
        // Alternar campo 'Nombre' según tipo de tarea
        rbGeneral.addActionListener(e -> {
            txtName.setEnabled(false);
            txtName.setText("");
        });

        rbSpecific.addActionListener(e -> {
            txtName.setEnabled(true);
            txtName.requestFocus();
        });

        // Botón Conectar
        btnConnect.addActionListener(e -> handleConnect());

        // Botón Añadir Tarea
        btnAdd.addActionListener(e -> handleAddTask());

        // Botón Recargar Tareas
        btnRefresh.addActionListener(e -> handleRefreshTasks());

        // Botón Salir
        btnExit.addActionListener(e -> safeDisconnectAndExit());
    }

    /**
     * Actualiza el estado de los controles según el estado de la conexión y si hay una operación en curso.
     */
    private void updateAppState(boolean connected, boolean isProcessing) {
        this.isConnectedToMainframe = connected;

        if (isProcessing) {
            btnConnect.setEnabled(false);
            btnRefresh.setEnabled(false);
            btnAdd.setEnabled(false);
            btnExit.setEnabled(false);
            txtDate.setEnabled(false);
            txtName.setEnabled(false);
            txtDesc.setEnabled(false);
            rbGeneral.setEnabled(false);
            rbSpecific.setEnabled(false);
        } else {
            btnConnect.setEnabled(!connected);
            btnRefresh.setEnabled(connected);
            btnAdd.setEnabled(connected);
            btnExit.setEnabled(true);
            txtDate.setEnabled(connected);
            rbGeneral.setEnabled(connected);
            rbSpecific.setEnabled(connected);
            txtDesc.setEnabled(connected);
            txtName.setEnabled(connected && rbSpecific.isSelected());
        }
    }

    /**
     * Proceso de conexión asíncrono con carga automática de tareas.
     */
    private void handleConnect() {
        setStatus("● Conectando al mainframe (155.210.152.51)...", new Color(180, 100, 0));
        updateAppState(false, true);

        new Thread(() -> {
            try {
                client.connect();
                client.login("grupo_03", "secreto6");
                client.startTasks();

                SwingUtilities.invokeLater(() -> {
                    setStatus("● Conectado a MUSIC/SP | Cargando tareas...", new Color(0, 130, 0));
                });

                // Carga inicial automática de tareas
                loadTasksFromMainframe();

                SwingUtilities.invokeLater(() -> {
                    setStatus("● Conectado a MUSIC/SP | Listo", new Color(0, 130, 0));
                    updateAppState(true, false);
                });

            } catch (Exception ex) {
                SwingUtilities.invokeLater(() -> {
                    setStatus("● Error de conexión: " + ex.getMessage(), Color.RED);
                    updateAppState(false, false);
                    JOptionPane.showMessageDialog(
                            this,
                            "Error al conectar con el mainframe:\n" + ex.getMessage(),
                            "Error de Conexión",
                            JOptionPane.ERROR_MESSAGE
                    );
                });
            }
        }).start();
    }

    /**
     * Proceso de creación de una nueva tarea validada.
     */
    private void handleAddTask() {
        String date = txtDate.getText().trim();
        String desc = txtDesc.getText().trim();
        boolean isSpecific = rbSpecific.isSelected();
        String name = isSpecific ? txtName.getText().trim() : "";

        // Validaciones
        if (!date.matches("\\d{4}")) {
            showValidationError("La fecha debe tener exactamente 4 dígitos (DDMM).", txtDate);
            return;
        }

        int day = Integer.parseInt(date.substring(0, 2));
        int month = Integer.parseInt(date.substring(2, 4));
        if (day < 1 || day > 31 || month < 1 || month > 12) {
            showValidationError("La fecha DDMM introducida no es válida en el calendario.", txtDate);
            return;
        }

        if (isSpecific) {
            if (name.isEmpty() || name.contains(" ") || name.length() > 20) {
                showValidationError("El nombre debe ser una única palabra sin espacios (máximo 20 caracteres).", txtName);
                return;
            }
        }

        if (desc.isEmpty() || desc.contains(" ") || desc.length() > 20) {
            showValidationError("La descripción debe ser una única palabra sin espacios (máximo 20 caracteres).", txtDesc);
            return;
        }

        setStatus("● Enviando tarea al mainframe...", new Color(180, 100, 0));
        updateAppState(true, true);

        new Thread(() -> {
            try {
                if (isSpecific) {
                    client.assignSpecificTask(date, name, desc);
                } else {
                    client.assignGeneralTask(date, desc);
                }
                client.backToMainMenu();

                // Recargamos la tabla para mostrar la tarea recién incorporada
                loadTasksFromMainframe();

                SwingUtilities.invokeLater(() -> {
                    txtDate.setText("");
                    txtName.setText("");
                    txtDesc.setText("");
                    setStatus("● Tarea creada con éxito | Listo", new Color(0, 130, 0));
                    updateAppState(true, false);
                });

            } catch (Exception ex) {
                try {
                    client.backToMainMenu();
                } catch (Exception ignored) {
                }

                SwingUtilities.invokeLater(() -> {
                    setStatus("● Error al crear la tarea: " + ex.getMessage(), Color.RED);
                    updateAppState(true, false);
                    JOptionPane.showMessageDialog(
                            this,
                            "No se pudo guardar la tarea en el mainframe:\n" + ex.getMessage(),
                            "Error de Operación",
                            JOptionPane.ERROR_MESSAGE
                    );
                });
            }
        }).start();
    }

    /**
     * Recarga las tareas desde el mainframe.
     */
    private void handleRefreshTasks() {
        setStatus("● Actualizando tareas desde el mainframe...", new Color(180, 100, 0));
        updateAppState(true, true);

        new Thread(() -> {
            try {
                loadTasksFromMainframe();
                SwingUtilities.invokeLater(() -> {
                    setStatus("● Tareas actualizadas con éxito | Listo", new Color(0, 130, 0));
                    updateAppState(true, false);
                });
            } catch (Exception ex) {
                SwingUtilities.invokeLater(() -> {
                    setStatus("● Error al refrescar tareas: " + ex.getMessage(), Color.RED);
                    updateAppState(true, false);
                });
            }
        }).start();
    }

    /**
     * Consulta las tareas generales y específicas del mainframe, las parsea y actualiza el JTable.
     */
    private void loadTasksFromMainframe() throws Exception {
        List<String> rawGenerales = client.getGeneralTasks();
        List<String> rawEspecificas = client.getSpecificTasks();

        List<Tarea> lista = new ArrayList<>();

        for (String raw : rawGenerales) {
            Tarea t = Tarea.parse(raw);
            if (t != null) {
                lista.add(t);
            }
        }

        for (String raw : rawEspecificas) {
            Tarea t = Tarea.parse(raw);
            if (t != null) {
                lista.add(t);
            }
        }

        // Ordenamos por ID de tarea
        lista.sort(Comparator.comparingInt(Tarea::getId));

        SwingUtilities.invokeLater(() -> {
            tableModel.setRowCount(0);
            for (Tarea t : lista) {
                tableModel.addRow(t.toTableRow());
            }
            lblCount.setText("Tareas: " + lista.size());
        });
    }

    private void showValidationError(String message, JTextField targetField) {
        JOptionPane.showMessageDialog(this, message, "Aviso de Validación", JOptionPane.WARNING_MESSAGE);
        targetField.requestFocus();
        targetField.selectAll();
    }

    private void setStatus(String text, Color color) {
        lblStatus.setText(text);
        lblStatus.setForeground(color);
    }

    /**
     * Protocolo de desconexión limpia respetando el retardo mínimo de 1.5 s para MUSIC/SP.
     */
    private void safeDisconnectAndExit() {
        if (!isConnectedToMainframe) {
            System.exit(0);
            return;
        }

        setStatus("● Desconectando de forma segura de MUSIC/SP...", new Color(180, 100, 0));
        updateAppState(false, true);

        new Thread(() -> {
            try {
                client.close();
            } catch (Exception ignored) {
            }

            try {
                Thread.sleep(1500);
            } catch (InterruptedException ignored) {
            }

            System.exit(0);
        }).start();
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new AppGUI().setVisible(true));
    }
}