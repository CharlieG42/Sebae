// MachineDetail.qml — Détail / édition d'une machine du parc
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  420
    height: 480
    title:  editMode ? "Modifier la machine" : "Détail de la machine"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property bool editMode: false
    property int  machineId: -1
    property var  contractOptions: maintBackend.getContractOptions()   // [{id, label}]
    property var  contractModel: {
        var lst = [""]
        for (var i = 0; i < contractOptions.length; i++) lst.push(contractOptions[i].label)
        return lst
    }

    signal saved()

    function loadData(data) {
        machineId = data && data.id !== undefined ? data.id : -1
        brandField.defaultText = (data && data.brand)     || ""
        typeField.defaultText  = (data && data.type)       || ""
        refField.defaultText   = (data && data.reference)  || ""
        yearField.defaultValue = (data && data.build_year) || 0
        locField.defaultText   = (data && data.location)   || ""

        contractOptions = maintBackend.getContractOptions()
        contractCombo.currentIndex = 0
        if (data && data.contract_id !== undefined && data.contract_id !== null) {
            for (var i = 0; i < contractOptions.length; i++) {
                if (contractOptions[i].id === data.contract_id) {
                    contractCombo.currentIndex = i + 1
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
                text: root.editMode ? "Modifier la machine" : "Détail de la machine"
                font.bold: true
                font.pointSize: 13
            }

            Txt { id: brandField; label: "Marque";    Layout.fillWidth: true; enabled: root.editMode }
            Txt { id: typeField;  label: "Type";       Layout.fillWidth: true; enabled: root.editMode }
            Txt { id: refField;   label: "Référence";  Layout.fillWidth: true; enabled: root.editMode }
            Num { id: yearField;  label: "Année de fabrication"; Layout.fillWidth: true; enabled: root.editMode }
            Txt { id: locField;   label: "Emplacement"; Layout.fillWidth: true; enabled: root.editMode }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Contrat rattaché (N° - Client)" }
                ComboBox {
                    id: contractCombo
                    model: root.contractModel
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
                        var contractId = contractCombo.currentIndex > 0
                            ? root.contractOptions[contractCombo.currentIndex - 1].id : null
                        var data = {
                            brand:       brandField.currentText,
                            type:        typeField.currentText,
                            reference:   refField.currentText,
                            build_year:  yearField.value,
                            location:    locField.currentText,
                            contract_id: contractId
                        }
                        if (root.machineId === -1) {
                            maintBackend.addMachine(data)
                        } else {
                            maintBackend.updateMachine(root.machineId, data)
                        }
                        root.saved()
                        root.visible = false
                    }
                }
            }
        }
    }
}
