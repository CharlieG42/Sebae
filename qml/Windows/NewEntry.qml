// NewEntry.qml — Fenêtre d'ajout d'une nouvelle pompe en BDD
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Modules/Common"

Window {
    id: newEntryWindow
    width:  260
    height: 590
    title:  "Ajouter une pompe"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    GroupBox {
        anchors.fill:    parent
        anchors.margins: 8
        title:           "Nouvelle pompe"

        ColumnLayout {
            spacing: 10
            width: parent.width

            Txt { id: brand;    label: "Marque";                width: parent.width }
            Txt { id: name;     label: "Nom / Référence";       width: parent.width }
            Num { id: flow;     label: "Débit nominal (m³/h)";  width: parent.width }
            Num { id: head;     label: "HMT nominale (mce)";    width: parent.width }
            Num { id: power;    label: "Puissance nominale (kW)"; width: parent.width }
            Num { id: effPump;  label: "Rendement pompe (%)";   width: parent.width }
            Num { id: effMotor; label: "Rendement moteur (%)";  width: parent.width }
            Txt { id: pn;       label: "Numéro de produit";     width: parent.width }

            Button {
                text:             "Enregistrer"
                Layout.fillWidth: true
                Material.accent:  Material.Indigo

                onClicked: {
                    var pump = {
                        BRAND:         brand.currentText,
                        NAME:          name.currentText,
                        NOMINAL_FLOW:  flow.value,
                        NOMINAL_HEAD:  head.value,
                        NOMINAL_POWER: power.value,
                        EFF_PUMP:      effPump.value,
                        EFF_MOTOR:     effMotor.value,
                        PN:            pn.currentText
                    }
                    backend.addValue("T_PUMPS", pump)
                    backend.updatePumpList(pump)
                    newEntryWindow.visible = false
                }
            }
        }
    }
}
