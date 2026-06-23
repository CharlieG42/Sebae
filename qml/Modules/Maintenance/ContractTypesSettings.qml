// ContractTypesSettings.qml — Paramètres des types de contrat (Bronze / Argent / Or)
// Champs structurés + description en texte libre, modifiables par l'utilisateur.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  640
    height: 600
    title:  "Paramètres — Types de contrat"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property var typesList: []
    property int selectedTypeId: -1

    function refresh() {
        typesList = maintBackend.getContractTypes()
        if (typesList.length > 0 && selectedTypeId === -1) {
            selectTypeAt(0)
        }
    }

    function selectTypeAt(idx) {
        if (idx < 0 || idx >= typesList.length) return
        var t = typesList[idx]
        selectedTypeId = t.id

        nameField.defaultText        = t.name || ""
        nbVisitsField.defaultValue   = t.nb_visits || 0
        responseField.defaultValue   = t.response_time_h || 0
        discountField.defaultValue   = t.discount_pct || 0
        priceField.defaultValue      = t.base_price || 0
        descField.text               = t.description || ""
        colorField.defaultText       = t.color || "#CCCCCC"
    }

    onVisibleChanged: if (visible) refresh()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // --- Liste des types ---
        Rectangle {
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            color: "#F5F5F5"
            border.color: "#DDDDDD"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Label { text: "Types de contrat"; font.bold: true }

                ListView {
                    id: typesListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.typesList
                    clip: true

                    delegate: ItemDelegate {
                        required property var modelData
                        required property int index
                        width: typesListView.width
                        highlighted: root.selectedTypeId === modelData.id

                        contentItem: RowLayout {
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: modelData.color || "#CCCCCC"
                            }
                            Text {
                                text: modelData.name
                                font.pixelSize: 13
                            }
                        }
                        onClicked: root.selectTypeAt(index)
                    }
                }

                Button {
                    text: "+ Nouveau type"
                    Layout.fillWidth: true
                    onClicked: {
                        var newId = maintBackend.addContractType({
                            name: "Nouveau type",
                            nb_visits: 1, response_time_h: 48, discount_pct: 0,
                            base_price: 0, description: "", color: "#90A4AE"
                        })
                        root.refresh()
                        for (var i = 0; i < root.typesList.length; i++) {
                            if (root.typesList[i].id === newId) { root.selectTypeAt(i); break }
                        }
                    }
                }
            }
        }

        // --- Édition du type sélectionné ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: root.width - 200
                anchors.margins: 16
                spacing: 12

                Label {
                    text: "Configuration du type"
                    font.bold: true
                    font.pointSize: 13
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                }

                Txt {
                    id: nameField
                    label: "Nom du type"
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                }

                Txt {
                    id: colorField
                    label: "Couleur (ex. #CD7F32)"
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                }

                RowLayout {
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.fillWidth: true
                    Num { id: nbVisitsField;  label: "Visites / an";          Layout.fillWidth: true }
                    Num { id: responseField;  label: "Délai interv. (h)";     Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.fillWidth: true
                    Num { id: discountField; label: "Remise pièces (%)";  Layout.fillWidth: true }
                    Num { id: priceField;    label: "Prix de base (€/an)"; Layout.fillWidth: true }
                }

                Label {
                    text: "Détail des prestations (texte libre)"
                    Layout.leftMargin: 16
                    Layout.topMargin: 8
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.preferredHeight: 160

                    TextArea {
                        id: descField
                        wrapMode: TextArea.WordWrap
                        placeholderText: "Description détaillée des prestations incluses..."
                        background: Rectangle { border.color: "#CCCCCC"; border.width: 1 }
                    }
                }

                RowLayout {
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.topMargin: 16
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        text: "Supprimer ce type"
                        Material.accent: Material.Red
                        onClicked: deleteConfirm.open()
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Enregistrer"
                        Material.accent: Material.Indigo
                        onClicked: {
                            maintBackend.updateContractType(root.selectedTypeId, {
                                name:            nameField.currentText,
                                nb_visits:       nbVisitsField.value,
                                response_time_h: responseField.value,
                                discount_pct:    discountField.value,
                                base_price:      priceField.value,
                                description:     descField.text,
                                color:           colorField.currentText
                            })
                            root.refresh()
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: deleteConfirm
        title: "Confirmer la suppression"
        modal: true
        standardButtons: Dialog.Yes | Dialog.Cancel
        anchors.centerIn: parent

        contentItem: Label {
            text: "Supprimer ce type de contrat ?\nLes contrats existants conserveront leur libellé actuel."
            wrapMode: Text.WordWrap
            padding: 16
        }

        onAccepted: {
            maintBackend.deleteContractType(root.selectedTypeId)
            root.selectedTypeId = -1
            root.refresh()
        }
    }
}
