// ContractDetail.qml — Détail / édition d'un contrat d'entretien
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  480
    height: 620
    title:  editMode ? "Modifier le contrat" : "Détail du contrat"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property bool editMode: false
    property var  contractData: null   // dict chargé depuis le backend
    property int  contractId: -1

    property var typeModel:   ["Bronze", "Argent", "Or"]
    property var statusModel: ["actif", "inactif", "en préparation"]

    // Options client : [{id, label}] — label au format "<ID_C4C> - <Nom>"
    property var clientOptions: maintBackend.getClientOptions()
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
            ? maintBackend.getContactOptionsForClient(clientId)
            : []
    }

    function loadData(data) {
        contractId   = data && data.id !== undefined ? data.id : -1
        contractData = data || {}

        contractNo.defaultText   = contractData.contract_no || ""
        statusCombo.currentIndex = Math.max(0, statusModel.indexOf(contractData.status || "en préparation"))
        startDate.defaultText    = contractData.start_date || ""
        endDate.defaultText      = contractData.end_date   || ""
        costField.defaultValue   = contractData.cost || 0
        typeCombo.currentIndex   = Math.max(0, typeModel.indexOf(contractData.contract_type || ""))

        clientOptions = maintBackend.getClientOptions()
        clientCombo.currentIndex = 0
        for (var i = 0; i < clientOptions.length; i++) {
            if (clientOptions[i].id === contractData.client_id) {
                clientCombo.currentIndex = i + 1   // +1 car "" en première position
                break
            }
        }

        _refreshContactOptions(contractData.client_id)
        contactCombo.currentIndex = 0
        for (var j = 0; j < contactOptions.length; j++) {
            if (contactOptions[j].id === contractData.contact_id) {
                contactCombo.currentIndex = j + 1
                break
            }
        }

        machinesRepeater.model = maintBackend.getMachinesForContract(contractId)
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
            width: root.width - 32
            spacing: 12

            Label {
                text: root.editMode ? "Modifier le contrat" : "Détail du contrat"
                font.bold: true
                font.pointSize: 13
            }

            Txt {
                id: contractNo
                label: "N° de contrat"
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
                        contactCombo.currentIndex = 0   // le contact dépend du client : on réinitialise
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

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Type de contrat" }
                ComboBox {
                    id: typeCombo
                    model: root.typeModel
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Statut" }
                ComboBox {
                    id: statusCombo
                    model: root.statusModel
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Txt {
                    id: startDate
                    label: "Date début (AAAA-MM-JJ)"
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
                Txt {
                    id: endDate
                    label: "Date fin (AAAA-MM-JJ)"
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
            }

            Num {
                id: costField
                label: "Coût (€)"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: "#EEEEEE" }

            Label { text: "Machines couvertes par ce contrat"; font.bold: true }

            Repeater {
                id: machinesRepeater
                delegate: Label {
                    required property var modelData
                    text: "• " + modelData.brand + " " + modelData.type + " (" + modelData.reference + ")"
                    font.pixelSize: 12
                }
            }
            Label {
                visible: machinesRepeater.count === 0
                text: "Aucune machine rattachée."
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
                            contract_no:   contractNo.currentText,
                            client_id:     clientId,
                            contact_id:    contactId,
                            contract_type: typeCombo.currentText,
                            status:        statusCombo.currentText,
                            start_date:    startDate.currentText,
                            end_date:      endDate.currentText,
                            cost:          costField.value
                        }

                        if (root.contractId === -1) {
                            maintBackend.addContract(data)
                        } else {
                            maintBackend.updateContract(root.contractId, data)
                        }
                        root.saved()
                        root.visible = false
                    }
                }
            }
        }
    }
}
