// main.qml — Fenêtre principale de Sebae
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "Modules/Common"
import "Modules/Maintenance"
import "Modules/Biz"
import "Modules/Disinfection"
import "Modules/WaterLift"
import "Windows"

ApplicationWindow {
    id: mainWindow
    visible:    true
    width:      820
    height:     1120
    minimumWidth:  700
    minimumHeight: 800
    title:      "Sebae"

    property string _version_: "0.2.0"

    Material.theme:   Material.Light
    Material.accent:  Material.Indigo
    Material.primary: Material.BlueGrey

    // --- Fenêtres secondaires ---
    NewEntry            { id: newEntry;             visible: false }
    OpenProject         { id: openProject;          visible: false }
    AdminWindow         { id: adminWindow;          visible: false }
    MaintenanceWindow   { id: maintenanceWindow;    visible: false }
    BizWindow           { id: bizWindow;            visible: false }  //Module pour les projets

    // --- Utilitaires QML ---
    Func { id: myFunctions }

    // -----------------------------------------------------------------------
    // Menu
    // -----------------------------------------------------------------------
    menuBar: MenuBar {

        Menu {
            title: qsTr("&Fichier")
            Action {
                text:        qsTr("&Ouvrir un projet...")
                onTriggered: openProject.visible = true
            }
            Action {
                text:        qsTr("&Ajouter une pompe...")
                onTriggered: newEntry.visible = true
            }
            MenuSeparator {}
            Action {
                text:        qsTr("&Quitter")
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: qsTr("&Admin")
            Action {
                text:        qsTr("&Connexion administrateur...")
                onTriggered: adminWindow.visible = true
            }
        }

        Menu {
            title: qsTr("&Contrats")
            Action {
                text:        qsTr("&Contrats d'entretien...")
                onTriggered: maintenanceWindow.visible = true
            }
        }

        Menu {
            title: qsTr("&Projets")
            Action {
                text:        qsTr("&Gestion des projets...")
                onTriggered: bizWindow.visible = true
            }
        }

        Menu {
            title: qsTr("&Aide")
            Action {
                text:        qsTr("&À propos")
                onTriggered: aboutDialog.open()
            }
        }
    }

    // -----------------------------------------------------------------------
    // Footer
    // -----------------------------------------------------------------------
    footer: ToolBar {
        height:        36
        contentHeight: 36
        background: Rectangle { color: "#EEEEEE" }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 10
            text:  mainWindow.title + "  v" + mainWindow._version_
            color: "#555555"
        }
    }

    // -----------------------------------------------------------------------
    // Contenu principal
    // -----------------------------------------------------------------------
    GridLayout {
        anchors.fill:    parent
        anchors.margins: 12
        columns:         2
        columnSpacing:   8
        rowSpacing:      8

        // Titre
        Text {
            text:                backend.title
            font.pointSize:      15
            font.bold:           true
            Layout.columnSpan:   2
            Layout.alignment:    Qt.AlignHCenter
        }

        // --- Groupe Projet -------------------------------------------------
        GroupBox {
            title:               "Projet"
            Layout.columnSpan:   2
            Layout.fillWidth:    true

            ColumnLayout {
                spacing: 8
                width:   parent.width

                Txt { id: project;    label: "Nom du projet";   width: parent.width }
                Txt { id: salesRep;   label: "Responsable";     width: parent.width }
                Txt { id: customer;   label: "Client";          width: parent.width }
                Num { id: energyCost; label: "Coût kWh (€/kWh):"; defaultValue: 0.20; width: 220 }
                Num { id: co2;        label: "Taux CO₂ (g/kWh):"; defaultValue: 69;   width: 220 }
            }
        }

        // --- Groupe Pompe 1 ------------------------------------------------
        GroupBox {
            title:            "Système actuel (Pompe 1)"
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent
                ColumnLayout {
                    spacing: 8

                    Combo {
                        id:           pump1
                        label:        "Matériel :"
                        model:        Object.keys(backend.pumps)
                        implicitWidth: 290
                        onValueChanged: {
                            var p = backend.pumps[currentText]
                            if (p) {
                                flowrate1.defaultValue = p.flowrate  || 0
                                head1.defaultValue     = p.head      || 0
                                pumpEff1.defaultValue  = p.pumpEff   || 0
                                motorEff1.defaultValue = p.motorEff  || 0
                            }
                        }
                    }

                    Combo {
                        id:    years1
                        label: "Année d'installation :"
                        model: {
                            var yr = new Date().getFullYear()
                            var lst = []
                            for (var y = yr - 20; y <= yr; y++) lst.push(y.toString())
                            return lst
                        }
                        Component.onCompleted: currentIndex = model.length - 11
                    }

                    Num { id: hours1;    label: "Heures / an :";       defaultValue: 2000; width: 200 }
                    Num { id: flowrate1; label: "Débit (m³/h) :";      width: 200 }
                    Num { id: head1;     label: "HMT (mce) :";         width: 200 }
                    Num { id: pumpEff1;  label: "Rend. pompe (%):";   width: 200 }
                    Num { id: motorEff1; label: "Rend. moteur (%):";  width: 200 }
                    Num { id: cost1;     label: "Coût (€) :";          defaultValue: 0; width: 200 }
                }
            }
        }

        // --- Groupe Pompe 2 ------------------------------------------------
        GroupBox {
            title:            "Nouveau système (Pompe 2)"
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent
                ColumnLayout {
                    spacing: 8

                    Combo {
                        id:           pump2
                        label:        "Matériel :"
                        model:        Object.keys(backend.pumps)
                        implicitWidth: 290
                        onValueChanged: {
                            var p = backend.pumps[currentText]
                            if (p) {
                                flowrate2.defaultValue = p.flowrate  || 0
                                head2.defaultValue     = p.head      || 0
                                pumpEff2.defaultValue  = p.pumpEff   || 0
                                motorEff2.defaultValue = p.motorEff  || 0
                            }
                        }
                    }

                    Combo {
                        id:    years2
                        label: "Année d'installation :"
                        model: {
                            var yr = new Date().getFullYear()
                            var lst = []
                            for (var y = yr - 20; y <= yr; y++) lst.push(y.toString())
                            return lst
                        }
                        Component.onCompleted: currentIndex = model.length - 1
                    }

                    Num { id: hours2;    label: "Heures / an :";       defaultValue: 2000; width: 200 }
                    Num { id: flowrate2; label: "Débit (m³/h) :";      width: 200 }
                    Num { id: head2;     label: "HMT (mce) :";         width: 200 }
                    Num { id: pumpEff2;  label: "Rend. pompe (%):";   width: 200 }
                    Num { id: motorEff2; label: "Rend. moteur (%):";  width: 200 }
                    Num { id: cost2;     label: "Coût (€) :";          defaultValue: 0; width: 200 }
                }
            }
        }

        // --- Boutons d'action -----------------------------------------------
        RowLayout {
            Layout.columnSpan: 2
            spacing: 10

            Button {
                text:            "Sauvegarder"
                Material.accent: Material.BlueGrey
                onClicked:       myFunctions.saveProject()
            }
            Button {
                text:            "Exporter rapport"
                Material.accent: Material.Indigo
                onClicked:       myFunctions.exportPDF()
            }
            Button {
                text:            "Sauvegarder et Exporter"
                Material.accent: Material.Indigo
                onClicked: {
                    myFunctions.saveProject()
                    myFunctions.exportPDF()
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // Dialogue À propos
    // -----------------------------------------------------------------------
    Dialog {
        id:              aboutDialog
        title:           "À propos"
        modal:           true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        contentItem: ColumnLayout {
            spacing: 10
            anchors.fill: parent
            anchors.margins: 16

            Text { text: "Sebae";   font.pointSize: 16; font.bold: true;
                   Layout.alignment: Qt.AlignHCenter }
            Text { text: "Version " + mainWindow._version_;
                   Layout.alignment: Qt.AlignHCenter }
            Text { text: "© 2026 — CEG-GFD\nLicences : LGPL-3.0 · MIT · PSF";
                   horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
            Text {
                text:      "Calcul de pertes de charges hydrauliques\net comparaison d'efficacité énergétique de pompes."
                wrapMode:  Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment:    Qt.AlignHCenter
                Layout.preferredWidth: 320
            }
        }
    }
}