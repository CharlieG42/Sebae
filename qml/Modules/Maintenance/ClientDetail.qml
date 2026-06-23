// ClientDetail.qml — Détail / édition d'un client
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  420
    height: 460
    title:  editMode ? "Modifier le client" : "Détail du client"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property bool editMode: false
    property int  clientId: -1

    signal saved()

    function loadData(data) {
        clientId = data && data.id !== undefined ? data.id : -1
        nameField.defaultText  = (data && data.name)   || ""
        idC4cField.defaultText = (data && data.id_c4c) || ""

        contactsRepeater.model = clientId >= 0
            ? maintBackend.getContacts().filter(function(c){ return c.client_id === clientId })
            : []
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
            width: root.width - 32
            spacing: 12

            Label {
                text: root.editMode ? "Modifier le client" : "Détail du client"
                font.bold: true
                font.pointSize: 13
            }

            Txt {
                id: nameField
                label: "Nom du client"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Txt {
                id: idC4cField
                label: "ID C4C"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: "#EEEEEE" }

            Label { text: "Contacts rattachés"; font.bold: true }
            Repeater {
                id: contactsRepeater
                delegate: Label {
                    required property var modelData
                    text: "• " + modelData.first_name + " " + modelData.last_name
                          + "  (" + (modelData.email || "—") + ")"
                    font.pixelSize: 12
                }
            }
            Label {
                visible: contactsRepeater.count === 0
                text: "Aucun contact rattaché."
                color: "#999999"
                font.italic: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                spacing: 10

                Button {
                    text: "Fermer"
                    Layout.fillWidth: true
                    onClicked: root.visible = false
                }
                Button {
                    text: "Enregistrer"
                    visible: root.editMode
                    Layout.fillWidth: true
                    Material.accent: Material.Indigo
                    onClicked: {
                        var data = {
                            name:   nameField.currentText,
                            id_c4c: idC4cField.currentText
                        }
                        if (root.clientId === -1) {
                            maintBackend.addClient(data)
                        } else {
                            maintBackend.updateClient(root.clientId, data)
                        }
                        root.saved()
                        root.visible = false
                    }
                }
            }
        }
    }
}
