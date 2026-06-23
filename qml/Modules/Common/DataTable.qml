// DataTable.qml — Tableau générique réutilisable pour les vues du module Contrats
// Fonctionnalités : recherche texte, tri par clic d'entête, boutons voir/modifier par ligne.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root

    // --- API publique -------------------------------------------------------
    property var    rows:        []        // liste de dicts (déjà chargée depuis le backend)
    property var    columns:     []        // [{key: "contract_no", title: "N° Contrat", width: 140}, ...]
    property string searchText:  searchField.text

    signal viewRequested(var row)
    signal editRequested(var row)

    // Colonne triée actuellement
    property string sortKey:    columns.length > 0 ? columns[0].key : ""
    property bool   sortAsc:    true

    // --- Filtrage + tri --------------------------------------------------------
    function _filteredSorted() {
        var txt = searchText.toLowerCase()
        var list = rows.filter(function(r) {
            if (txt === "") return true
            for (var i = 0; i < columns.length; i++) {
                var v = r[columns[i].key]
                if (v !== undefined && v !== null &&
                    String(v).toLowerCase().indexOf(txt) !== -1) return true
            }
            return false
        })
        list.sort(function(a, b) {
            var va = a[root.sortKey], vb = b[root.sortKey]
            if (va === undefined || va === null) va = ""
            if (vb === undefined || vb === null) vb = ""
            var cmp = (va < vb) ? -1 : (va > vb ? 1 : 0)
            return root.sortAsc ? cmp : -cmp
        })
        return list
    }

    property var displayedRows: _filteredSorted()

    onRowsChanged:       displayedRows = _filteredSorted()
    onSearchTextChanged: displayedRows = _filteredSorted()
    onSortKeyChanged:    displayedRows = _filteredSorted()
    onSortAscChanged:    displayedRows = _filteredSorted()

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // --- Barre de recherche ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                placeholderText: "Rechercher..."
                Layout.fillWidth: true
            }
            Label {
                text:  root.displayedRows.length + " résultat(s)"
                color: "#888888"
            }
        }

        // --- En-têtes triables ---
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color:  "#E8EAF6"
            border.color: "#CCCCCC"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.columns
                    delegate: MouseArea {
                        Layout.preferredWidth: modelData.width || 120
                        Layout.fillHeight:     true
                        onClicked: {
                            if (root.sortKey === modelData.key) {
                                root.sortAsc = !root.sortAsc
                            } else {
                                root.sortKey = modelData.key
                                root.sortAsc = true
                            }
                        }
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 4
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                font.bold: true
                                font.pixelSize: 12
                            }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.sortKey === modelData.key
                                text:    root.sortAsc ? "▲" : "▼"
                                font.pixelSize: 10
                                color: Material.accent
                            }
                        }
                    }
                }
                // Colonne actions
                Item { Layout.preferredWidth: 90; Layout.fillHeight: true }
            }
        }

        // --- Lignes ---
        ListView {
            id: listView
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip: true
            model: root.displayedRows

            delegate: Rectangle {
                id: rowDelegate
                width:  listView.width
                height: 38
                color:  index % 2 === 0 ? "#FFFFFF" : "#F9F9F9"
                border.color: "#EFEFEF"
                border.width: 1

                required property var modelData
                property var rowData: modelData

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: root.columns
                        delegate: Label {
                            required property var modelData
                            Layout.preferredWidth: modelData.width || 120
                            Layout.fillHeight:     true
                            leftPadding:            8
                            verticalAlignment:      Text.AlignVCenter
                            elide:                  Text.ElideRight
                            text: {
                                var v = rowDelegate.rowData[modelData.key]
                                return v !== undefined && v !== null ? String(v) : ""
                            }
                        }
                    }

                    // Actions voir / modifier
                    RowLayout {
                        Layout.preferredWidth: 90
                        Layout.fillHeight: true
                        spacing: 4

                        ToolButton {
                            text: "👁"
                            implicitWidth: 36
                            ToolTip.text: "Voir"
                            ToolTip.visible: hovered
                            onClicked: root.viewRequested(rowDelegate.rowData)
                        }
                        ToolButton {
                            text: "✎"
                            implicitWidth: 36
                            ToolTip.text: "Modifier"
                            ToolTip.visible: hovered
                            onClicked: root.editRequested(rowDelegate.rowData)
                        }
                    }
                }
            }
        }
    }
}
