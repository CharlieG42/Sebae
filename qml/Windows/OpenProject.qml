// OpenProject.qml — Fenêtre de chargement d'un projet existant
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Modules/Common"

Window {
    id: openProjectWindow
    width:  420
    height: 220
    title:  "Ouvrir un projet"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property var selectedProject: null

    GroupBox {
        anchors.fill:    parent
        anchors.margins: 8
        title:           "Sélectionner un projet"

        ColumnLayout {
            spacing: 10
            width: parent.width

            Combo {
                id:           projectSelection
                label:        "Projet :"
                model:        Object.keys(backend.projects)
                implicitWidth: parent.width

                onValueChanged: {
                    openProjectWindow.selectedProject = backend.projects[currentText]
                }
            }

            Button {
                text:             "Importer"
                Layout.fillWidth: true
                enabled:          openProjectWindow.selectedProject !== null &&
                                  openProjectWindow.selectedProject !== ""
                Material.accent:  Material.Indigo

                onClicked: {
                    var sp = openProjectWindow.selectedProject
                    if (!sp || sp === "") return

                    var p1 = JSON.parse(sp.pump1 || "{}")
                    var p2 = JSON.parse(sp.pump2 || "{}")

                    // Pompe 1
                    pump1.defaultValue      = p1.name      || ""
                    years1.defaultValue     = p1.year      || ""
                    hours1.defaultValue     = p1.hours     || 0
                    flowrate1.defaultValue  = p1.flowrate  || 0
                    head1.defaultValue      = p1.head      || 0
                    pumpEff1.defaultValue   = p1.pumpEff   || 0
                    motorEff1.defaultValue  = p1.motorEff  || 0
                    cost1.defaultValue      = p1.cost      || 0

                    // Pompe 2
                    pump2.defaultValue      = p2.name      || ""
                    years2.defaultValue     = p2.year      || ""
                    hours2.defaultValue     = p2.hours     || 0
                    flowrate2.defaultValue  = p2.flowrate  || 0
                    head2.defaultValue      = p2.head      || 0
                    pumpEff2.defaultValue   = p2.pumpEff   || 0
                    motorEff2.defaultValue  = p2.motorEff  || 0
                    cost2.defaultValue      = p2.cost      || 0

                    // Projet
                    project.defaultText     = sp.name      || ""
                    customer.defaultText    = sp.customer  || ""
                    salesRep.defaultText    = sp.salesRep  || ""
                    energyCost.defaultValue = sp.nrjCost   || 0
                    co2.defaultValue        = sp.co2Coef   || 0

                    openProjectWindow.visible = false
                }
            }
        }
    }
}
