// ArticleDetail.qml — Détail / édition d'un article de projet
// Calculs dynamiques : PCTM, PCTR, GRPi recalculés à la saisie.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"

Window {
    id: root
    width:  460
    height: 660
    title:  editMode ? "Modifier l'article" : "Détail de l'article"
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property bool editMode: false
    property int  articleId: -1

    property var typeModel: bizBackend.getArticleTypes()

    property var projectOptions: bizBackend.getProjectOptions()
    property var projectModel: {
        var lst = [""]
        for (var i = 0; i < projectOptions.length; i++) lst.push(projectOptions[i].label)
        return lst
    }

    signal saved()

    // --- Calculs dynamiques ---
    property real calcPctm: {
        var qty   = parseFloat(qtyField.value)   || 0
        var cost  = parseFloat(costField.value)  || 0
        var price = parseFloat(priceField.value) || 0
        return (price - cost) * qty
    }
    property real calcPctr: {
        var price = parseFloat(priceField.value) || 0
        return price !== 0 ? (calcPctm / price * 100) : 0
    }
    property real calcGrpi: {
        var price = parseFloat(priceField.value) || 0
        var grp   = parseFloat(grpField.value)    || 0
        return grp !== 0 ? (price * 100 / grp) : 0
    }

    function loadData(data) {
        articleId = data && data.id !== undefined ? data.id : -1

        articleNo.defaultText    = (data && data.article_no)  || ""
        designationField.defaultText = (data && data.designation) || ""
        typeCombo.currentIndex   = Math.max(0, typeModel.indexOf(data && data.article_type))
        qtyField.defaultValue    = (data && data.quantity)    || 1
        costField.defaultValue   = (data && data.total_cost)  || 0
        priceField.defaultValue  = (data && data.sale_price)  || 0
        grpField.defaultValue    = (data && data.grp)         || 0
        mpgField.defaultText     = (data && data.mpg)          || ""

        projectOptions = bizBackend.getProjectOptions()
        projectCombo.currentIndex = 0
        if (data && data.project_id !== undefined && data.project_id !== null) {
            for (var i = 0; i < projectOptions.length; i++) {
                if (projectOptions[i].id === data.project_id) {
                    projectCombo.currentIndex = i + 1
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
                text: root.editMode ? "Modifier l'article" : "Détail de l'article"
                font.bold: true
                font.pointSize: 13
            }

            Txt {
                id: articleNo
                label: "N° d'article"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Txt {
                id: designationField
                label: "Désignation"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Projet (N° - Nom)" }
                ComboBox {
                    id: projectCombo
                    model: root.projectModel
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Type d'article" }
                ComboBox {
                    id: typeCombo
                    model: root.typeModel
                    Layout.fillWidth: true
                    enabled: root.editMode
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Num { id: qtyField;   label: "Quantité";          Layout.fillWidth: true; enabled: root.editMode }
                Num { id: costField;  label: "Coût total (€)";    Layout.fillWidth: true; enabled: root.editMode }
            }

            RowLayout {
                Layout.fillWidth: true
                Num { id: priceField; label: "Prix de vente (€)"; Layout.fillWidth: true; enabled: root.editMode }
                Num { id: grpField;   label: "GRP (€)";            Layout.fillWidth: true; enabled: root.editMode }
            }

            Txt {
                id: mpgField
                label: "MPG (code 2 lettres)"
                Layout.fillWidth: true
                enabled: root.editMode
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: "#EEEEEE" }

            Label { text: "Calculs"; font.bold: true }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 16
                rowSpacing: 6

                Label { text: "PCTM (marge en valeur) :" }
                Label { text: root.calcPctm.toFixed(2) + " €"; font.bold: true }

                Label { text: "PCTR (marge en %) :" }
                Label { text: root.calcPctr.toFixed(2) + " %"; font.bold: true }

                Label { text: "GRPi :" }
                Label { text: root.calcGrpi.toFixed(2); font.bold: true }
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
                        var projectId = projectCombo.currentIndex > 0
                            ? root.projectOptions[projectCombo.currentIndex - 1].id : null

                        var data = {
                            article_no:   articleNo.currentText,
                            project_id:   projectId,
                            designation:  designationField.currentText,
                            article_type: typeCombo.currentText,
                            quantity:     qtyField.value,
                            total_cost:   costField.value,
                            sale_price:   priceField.value,
                            grp:          grpField.value,
                            mpg:          mpgField.currentText
                        }

                        if (root.articleId === -1) {
                            bizBackend.addArticle(data)
                        } else {
                            bizBackend.updateArticle(root.articleId, data)
                        }
                        root.saved()
                        root.visible = false
                    }
                }
            }
        }
    }
}
