// ProjectDetail.qml — Détail / édition d'un projet commercial
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  480
    height: 560
    title:  editMode ? "Modifier le projet" : "Détail du projet"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property bool editMode: false
    property var  projectData: null
    property int  projectId: -1

    // Options client : [{id, label}] — label "<ID_C4C> - <Nom>"
    property var clientOptions: bizBackend.getClientOptions()
    property var clientModel: {
        var lst = [""]
        for (var i = 0; i < clientOptions.length; i++) lst.push(clientOptions[i].label)
        return lst
    }

    // Options contact : dépendent du client sélectionné
    property var contactOptions: []
    property var contactModel: {
        var lst = [""]
        for (var i = 0; i < contactOptions.length; i++) lst.push(contactOptions[i].label)
        return lst
    }

    signal saved()

    function _refreshContactOptions(clientId) {
        contactOptions = (clientId !== null && clientId !== undefined)
            ? bizBackend.getContactOptionsForClient(clientId)
            : []
    }

    function loadData(data) {
        projectId   = data && data.id !== undefined ? data.id : -1
        projectData = data || {}

        projectNo.defaultText = projectData.project_no || ""
        nameField.defaultText = projectData.name        || ""
        cityField.defaultText = projectData.city         || ""

        clientOptions = bizBackend.getClientOptions()
        clientCombo.currentIndex = 0
        for (var i = 0; i < clientOptions.length; i++) {
            if (clientOptions[i].id === projectData.client_id) {
                clientCombo.currentIndex = i + 1
                break
            }
        }

        _refreshContactOptions(projectData.client_id)
        contactCombo.currentIndex = 0
        for (var j = 0; j < contactOptions.length; j++) {
            if (contactOptions[j].id === projectData.contact_id) {
                contactCombo.currentIndex = j + 1
                break
            }
        }

        articlesRepeater.model = projectId >= 0 ? bizBackend.getArticlesForProject(projectId) : []
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
            width: root.width - 32
            spacing: 12

            Label {
                text: root.editMode ? "Modifier le projet" : "Détail du projet"
                font.bold: true
                font.pointSize: 13
            }

            Txt {
                id: projectNo
                label: "N° de projet"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Txt {
                id: nameField
                label: "Nom du projet"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Txt {
                id: cityField
                label: "Ville du projet"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Client (ID C4C - Nom)" }
                ComboBox {
                    id: clientCombo
                    model: root.clientModel
                    Layout.fillWidth: true
                    enabled: root.editMode

                    onActivated: {
                        var clientId = currentIndex > 0 ? root.clientOptions[currentIndex - 1].id : null
                        root._refreshContactOptions(clientId)
                        contactCombo.currentIndex = 0
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Contact" }
                ComboBox {
                    id: contactCombo
                    model: root.contactModel
                    Layout.fillWidth: true
                    enabled: root.editMode && root.contactOptions.length > 0
                }
                Label {
                    visible: root.editMode && root.contactOptions.length === 0
                    text: "Aucun contact pour ce client."
                    color: "#999999"
                    font.pixelSize: 11
                    font.italic: true
                }
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: "#EEEEEE" }

            Label { text: "Articles du projet"; font.bold: true }

            Repeater {
                id: articlesRepeater
                delegate: Label {
                    required property var modelData
                    text: "• " + modelData.article_no + " — " + modelData.designation
                          + "  (PCTM " + modelData.pctm + " € · PCTR " + modelData.pctr + " %)"
                    font.pixelSize: 12
                }
            }
            Label {
                visible: articlesRepeater.count === 0
                text: "Aucun article rattaché."
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
                        var clientId = clientCombo.currentIndex > 0
                            ? root.clientOptions[clientCombo.currentIndex - 1].id : null
                        var contactId = contactCombo.currentIndex > 0
                            ? root.contactOptions[contactCombo.currentIndex - 1].id : null

                        var data = {
                            project_no: projectNo.currentText,
                            name:       nameField.currentText,
                            city:       cityField.currentText,
                            client_id:  clientId,
                            contact_id: contactId
                        }

                        if (root.projectId === -1) {
                            bizBackend.addProject(data)
                        } else {
                            bizBackend.updateProject(root.projectId, data)
                        }
                        root.saved()
                        root.visible = false
                    }
                }
            }
        }
    }
}
