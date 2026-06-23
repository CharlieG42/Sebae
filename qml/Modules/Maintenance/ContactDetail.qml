// ContactDetail.qml — Détail / édition d'un contact
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  400
    height: 420
    title:  editMode ? "Modifier le contact" : "Détail du contact"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property bool editMode: false
    property int  contactId: -1
    property var  clientOptions: maintBackend.getClientOptions()   // [{id, label}]
    property var  clientModel: {
        var lst = [""]
        for (var i = 0; i < clientOptions.length; i++) lst.push(clientOptions[i].label)
        return lst
    }

    signal saved()

    function loadData(data) {
        contactId = data && data.id !== undefined ? data.id : -1
        lastName.defaultText  = (data && data.last_name)  || ""
        firstName.defaultText = (data && data.first_name) || ""
        emailField.defaultText  = (data && data.email)  || ""
        mobileField.defaultText = (data && data.mobile) || ""

        clientOptions = maintBackend.getClientOptions()
        clientCombo.currentIndex = 0
        if (data && data.client_id !== undefined && data.client_id !== null) {
            for (var i = 0; i < clientOptions.length; i++) {
                if (clientOptions[i].id === data.client_id) {
                    clientCombo.currentIndex = i + 1
                    break
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
            width: root.width - 32
            spacing: 12

            Label {
                text: root.editMode ? "Modifier le contact" : "Détail du contact"
                font.bold: true
                font.pointSize: 13
            }

            RowLayout {
                Layout.fillWidth: true
                Txt { id: firstName; label: "Prénom"; Layout.fillWidth: true; enabled: root.editMode }
                Txt { id: lastName;  label: "Nom";     Layout.fillWidth: true; enabled: root.editMode }
            }

            Txt { id: emailField;  label: "Email";  Layout.fillWidth: true; enabled: root.editMode }
            Txt { id: mobileField; label: "Mobile";  Layout.fillWidth: true; enabled: root.editMode }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Client (ID C4C - Nom)" }
                ComboBox {
                    id: clientCombo
                    model: root.clientModel
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
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
                        var clientId = null
                        if (clientCombo.currentIndex > 0) {
                            clientId = root.clientOptions[clientCombo.currentIndex - 1].id
                        }
                        var data = {
                            first_name: firstName.currentText,
                            last_name:  lastName.currentText,
                            email:      emailField.currentText,
                            mobile:     mobileField.currentText,
                            client_id:  clientId
                        }
                        if (root.contactId === -1) {
                            maintBackend.addContact(data)
                        } else {
                            maintBackend.updateContact(root.contactId, data)
                        }
                        root.saved()
                        root.visible = false
                    }
                }
            }
        }
    }
}
