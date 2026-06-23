// AdminWindow.qml — Fenêtre d'administration de la base de données
// Accès protégé par login/mot de passe (credentials dans config.toml)
// Fonctionnalités : visualisation, modification inline, suppression de lignes
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt.labs.qmlmodels

Window {
    id: adminWindow
    title:      "Administration — Base de données"
    width:      1100
    height:     700
    minimumWidth:  820
    minimumHeight: 480
    visible:    false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property string currentTable: ""

    // --- Réactions aux signaux backend -------------------------------------
    Connections {
        target: backend

        function onAdminStatusChanged(isAdmin) {
            loginOverlay.visible = !isAdmin
            if (!isAdmin) passwordField.text = ""
        }

        function onAdminErrorChanged() {
            errorLabel.text = backend.adminError
        }

        function onTableContentChanged() {
            tableView.forceLayout()
        }
    }

    // =======================================================================
    // Layout principal
    // =======================================================================
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // --- Colonne gauche : liste des tables ----------------------------
        Rectangle {
            Layout.preferredWidth: 210
            Layout.fillHeight:     true
            color:                 "#F5F5F5"
            border.color:          "#DDDDDD"
            border.width:          1

            ColumnLayout {
                anchors.fill:    parent
                anchors.margins: 8
                spacing:         6

                Label {
                    text:           "Tables"
                    font.bold:      true
                    font.pointSize: 11
                }
                Rectangle { height: 1; Layout.fillWidth: true; color: "#CCCCCC" }

                ListView {
                    id:                tableListView
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    model:             backend.tableList
                    clip:              true

                    delegate: ItemDelegate {
                        width:       tableListView.width
                        highlighted: adminWindow.currentTable === modelData

                        contentItem: Text {
                            text:              modelData
                            font.pixelSize:    13
                            color:             adminWindow.currentTable === modelData
                                               ? Material.accent : "#333333"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding:       8
                        }
                        background: Rectangle {
                            color:  adminWindow.currentTable === modelData ? "#E8EAF6"
                                    : (parent.hovered ? "#EFEFEF" : "transparent")
                            radius: 4
                        }
                        onClicked: {
                            adminWindow.currentTable = modelData
                            backend.loadTable(modelData)
                        }
                    }
                }

                Button {
                    text:             "Déconnexion"
                    Layout.fillWidth: true
                    Material.accent:  Material.Red
                    onClicked: {
                        adminWindow.currentTable = ""
                        backend.adminLogout()
                        adminWindow.visible = false
                    }
                }
            }
        }

        // --- Zone droite : contenu de la table ----------------------------
        ColumnLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing:           0

            // En-tête
            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: 44
                color:        "#FFFFFF"
                border.color: "#DDDDDD"
                border.width: 1

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: 10

                    Label {
                        text: adminWindow.currentTable !== ""
                              ? "Table : <b>" + adminWindow.currentTable + "</b>"
                              : "← Sélectionnez une table"
                        textFormat:     Text.RichText
                        font.pointSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text:    backend.tableRows.length + " ligne(s)"
                        color:   "#888888"
                        visible: adminWindow.currentTable !== ""
                    }
                }
            }

            // En-tête des colonnes
            HorizontalHeaderView {
                id:               horizontalHeader
                syncView:         tableView
                Layout.fillWidth: true
                clip:             true

                delegate: Rectangle {
                    implicitHeight: 32
                    color:          "#E8EAF6"
                    border.color:   "#CCCCCC"
                    border.width:   1

                    Text {
                        anchors.centerIn: parent
                        text:             backend.tableCols[index] ?? ""
                        font.bold:        true
                        font.pixelSize:   12
                        color:            "#333333"
                    }
                }
            }

            // Tableau de données
            TableView {
                id:                tableView
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip:              true
                columnSpacing:     1
                rowSpacing:        1

                model: TableModel {
                    id: tableModel
                    TableModelColumn { display: "col" }
                    rows: backend.tableRows.map(function(row) {
                        return row.map(function(cell) { return {"col": cell} })
                    })
                }

                columnWidthProvider: function(col) {
                    if (backend.tableCols.length === 0) return 0
                    return Math.max(80, tableView.width / backend.tableCols.length)
                }

                delegate: Rectangle {
                    implicitHeight: 36
                    color:          row % 2 === 0 ? "#FFFFFF" : "#F9F9F9"
                    border.color:   "#E0E0E0"
                    border.width:   1

                    // Affichage normal
                    Text {
                        id:                cellText
                        anchors.fill:      parent
                        anchors.margins:   6
                        text:              display
                        font.pixelSize:    12
                        verticalAlignment: Text.AlignVCenter
                        elide:             Text.ElideRight
                        visible:           !cellEditor.visible
                    }

                    // Éditeur inline (double-clic, colonne id exclue)
                    TextField {
                        id:           cellEditor
                        anchors.fill: parent
                        text:         display
                        visible:      false
                        font.pixelSize: 12

                        onEditingFinished: {
                            if (text !== display && adminWindow.currentTable !== "") {
                                var rowId   = parseInt(backend.tableRows[row][0])
                                var colName = backend.tableCols[column]
                                backend.adminUpdateCell(adminWindow.currentTable, rowId, colName, text)
                                backend.loadTable(adminWindow.currentTable)
                            }
                            cellEditor.visible = false
                        }
                        Keys.onEscapePressed: cellEditor.visible = false
                    }

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                            if (column > 0) {   // colonne 0 = id, non éditable
                                cellEditor.text    = display
                                cellEditor.visible = true
                                cellEditor.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // Barre d'actions — suppression par ID
            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: 50
                color:        "#FAFAFA"
                border.color: "#DDDDDD"
                border.width: 1
                visible:      adminWindow.currentTable !== ""

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: 8
                    spacing:         10

                    Label {
                        text:  "Double-clic sur une cellule pour modifier  •  ID à supprimer :"
                        color: "#666666"
                        font.pixelSize: 11
                    }
                    TextField {
                        id:             deleteIdField
                        placeholderText: "ID"
                        implicitWidth:  60
                        implicitHeight: 32
                        validator:      IntValidator { bottom: 1 }
                    }
                    Button {
                        text:            "Supprimer"
                        Material.accent: Material.Red
                        enabled:         deleteIdField.text.length > 0
                        onClicked:       confirmDeleteDialog.open()
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    // =======================================================================
    // Overlay de login
    // =======================================================================
    Rectangle {
        id:      loginOverlay
        anchors.fill: parent
        color:   "#CC000000"
        visible: true
        z:       10

        Rectangle {
            anchors.centerIn: parent
            width:  370
            height: 270
            radius: 10
            color:  "#FFFFFF"

            ColumnLayout {
                anchors.centerIn: parent
                width:   320
                spacing: 14

                Label {
                    text:              "Connexion Administrateur"
                    font.bold:         true
                    font.pointSize:    13
                    Layout.alignment:  Qt.AlignHCenter
                }
                Rectangle { height: 1; Layout.fillWidth: true; color: "#EEEEEE" }

                TextField {
                    id:               loginField
                    placeholderText:  "Login"
                    Layout.fillWidth: true
                    text:             "admin"
                    onAccepted:       passwordField.forceActiveFocus()
                }
                TextField {
                    id:               passwordField
                    placeholderText:  "Mot de passe"
                    Layout.fillWidth: true
                    echoMode:         TextInput.Password
                    onAccepted:       loginButton.clicked()
                }
                Label {
                    id:               errorLabel
                    text:             ""
                    color:            "#D32F2F"
                    wrapMode:         Text.WordWrap
                    Layout.fillWidth: true
                    font.pixelSize:   12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        text:             "Annuler"
                        Layout.fillWidth: true
                        onClicked: {
                            errorLabel.text        = ""
                            adminWindow.visible    = false
                        }
                    }
                    Button {
                        id:               loginButton
                        text:             "Connexion"
                        Layout.fillWidth: true
                        Material.accent:  Material.Indigo
                        onClicked: {
                            errorLabel.text = ""
                            backend.adminLogin(loginField.text, passwordField.text)
                        }
                    }
                }
            }
        }
    }

    // =======================================================================
    // Dialogue confirmation suppression
    // =======================================================================
    Dialog {
        id:              confirmDeleteDialog
        title:           "Confirmer la suppression"
        modal:           true
        standardButtons: Dialog.Yes | Dialog.Cancel
        anchors.centerIn: parent

        contentItem: Label {
            text:       "Supprimer la ligne ID <b>" + deleteIdField.text
                        + "</b> de la table <b>" + adminWindow.currentTable + "</b> ?"
            textFormat: Text.RichText
            wrapMode:   Text.WordWrap
            padding:    16
        }

        onAccepted: {
            backend.adminDeleteRow(adminWindow.currentTable, parseInt(deleteIdField.text))
            deleteIdField.text = ""
        }
    }
}
