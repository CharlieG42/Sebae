// BizWindow.qml — Fenêtre principale du module "Projet"
// Navigation entre les vues Projets / Articles.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"
import "."

Window {
    id: root
    title:  "Projets"
    width:  1150
    height: 700
    minimumWidth:  900
    minimumHeight: 550
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property int currentView: 0   // 0=Projets 1=Articles

    ProjectDetail { id: projectDetail; onSaved: root.reloadAll() }
    ArticleDetail { id: articleDetail; onSaved: root.reloadAll() }

    property var projectsData: []
    property var articlesData: []

    function reloadAll() {
        projectsData = bizBackend.getProjects()
        articlesData = bizBackend.getArticles()
    }

    onVisibleChanged: if (visible) reloadAll()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            currentIndex: root.currentView
            onCurrentIndexChanged: root.currentView = currentIndex

            TabButton { text: "📁 Projets" }
            TabButton { text: "📦 Articles" }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            Button {
                text: root.currentView === 0 ? "+ Nouveau projet" : "+ Nouvel article"
                Material.accent: Material.Indigo
                onClicked: {
                    if (root.currentView === 0) {
                        projectDetail.editMode = true
                        projectDetail.loadData(null)
                        projectDetail.visible = true
                    } else {
                        articleDetail.editMode = true
                        articleDetail.loadData(null)
                        articleDetail.visible = true
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        StackLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            Layout.margins: 8
            currentIndex: root.currentView

            // --- Vue Projets ---
            DataTable {
                rows: root.projectsData
                columns: [
                    {key: "project_no",   title: "N° Projet", width: 120},
                    {key: "name",         title: "Nom",        width: 200},
                    {key: "city",         title: "Ville",      width: 140},
                    {key: "client_label", title: "Client",     width: 190},
                    {key: "contact_name", title: "Contact",    width: 140},
                ]
                onViewRequested: function(row) {
                    projectDetail.editMode = false
                    projectDetail.loadData(bizBackend.getProject(row.id))
                    projectDetail.visible = true
                }
                onEditRequested: function(row) {
                    projectDetail.editMode = true
                    projectDetail.loadData(bizBackend.getProject(row.id))
                    projectDetail.visible = true
                }
            }

            // --- Vue Articles ---
            DataTable {
                rows: root.articlesData
                columns: [
                    {key: "article_no",   title: "N° Article",  width: 100},
                    {key: "designation",  title: "Désignation", width: 170},
                    {key: "project_label",title: "Projet",      width: 150},
                    {key: "article_type", title: "Type",        width: 130},
                    {key: "quantity",     title: "Qté",         width: 60},
                    {key: "total_cost",   title: "Coût total",  width: 90},
                    {key: "sale_price",   title: "Prix vente",  width: 90},
                    {key: "pctm",         title: "PCTM",        width: 80},
                    {key: "pctr",         title: "PCTR (%)",    width: 80},
                    {key: "grp",          title: "GRP",         width: 70},
                    {key: "grpi",         title: "GRPi",        width: 70},
                    {key: "mpg",          title: "MPG",         width: 60},
                ]
                onViewRequested: function(row) {
                    articleDetail.editMode = false
                    articleDetail.loadData(bizBackend.getArticle(row.id))
                    articleDetail.visible = true
                }
                onEditRequested: function(row) {
                    articleDetail.editMode = true
                    articleDetail.loadData(bizBackend.getArticle(row.id))
                    articleDetail.visible = true
                }
            }
        }
    }
}
