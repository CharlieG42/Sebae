// MaintenanceWindow.qml — Fenêtre principale du module "Contrats d'entretien"
// Navigation entre les vues Contrats / Clients / Contacts / Machines.
// Clic sur une cellule liée (ex. client d'un contrat) bascule vers la vue correspondante.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "../Common"
import "."

Window {
    id: root
    title:  "Contrats d'entretien"
    width:  1100
    height: 700
    minimumWidth:  900
    minimumHeight: 550
    visible: false

    Material.theme:  Material.Light
    Material.accent: Material.Indigo

    property int currentView: 0   // 0=Contrats 1=Clients 2=Contacts 3=Machines

    // --- Fenêtres de détail ---
    ContractDetail { id: contractDetail; onSaved: root.reloadAll() }
    ClientDetail   { id: clientDetail;   onSaved: root.reloadAll() }
    ContactDetail  { id: contactDetail;  onSaved: root.reloadAll() }
    MachineDetail  { id: machineDetail;  onSaved: root.reloadAll() }
    ContractTypesSettings { id: typesSettings }

    property var contractsData: []
    property var clientsData:   []
    property var contactsData:  []
    property var machinesData:  []

    function reloadAll() {
        contractsData = maintBackend.getContracts()
        clientsData   = maintBackend.getClients()
        contactsData  = maintBackend.getContacts()
        machinesData  = maintBackend.getMachines()
    }

    onVisibleChanged: if (visible) reloadAll()

    function openClientById(clientId) {
        for (var i = 0; i < clientsData.length; i++) {
            if (clientsData[i].id === clientId) {
                currentView = 1
                return
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- Barre d'onglets ---
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            currentIndex: root.currentView
            onCurrentIndexChanged: root.currentView = currentIndex

            TabButton { text: "📄 Contrats" }
            TabButton { text: "🏢 Clients" }
            TabButton { text: "👤 Contacts" }
            TabButton { text: "⚙ Machines" }
        }

        // --- Barre d'actions ---
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            Button {
                text: {
                    switch(root.currentView) {
                        case 0: return "+ Nouveau contrat"
                        case 1: return "+ Nouveau client"
                        case 2: return "+ Nouveau contact"
                        case 3: return "+ Nouvelle machine"
                    }
                }
                Material.accent: Material.Indigo
                onClicked: {
                    switch(root.currentView) {
                        case 0:
                            contractDetail.editMode = true
                            contractDetail.loadData(null)
                            contractDetail.visible = true
                            break
                        case 1:
                            clientDetail.editMode = true
                            clientDetail.loadData(null)
                            clientDetail.visible = true
                            break
                        case 2:
                            contactDetail.editMode = true
                            contactDetail.loadData(null)
                            contactDetail.visible = true
                            break
                        case 3:
                            machineDetail.editMode = true
                            machineDetail.loadData(null)
                            machineDetail.visible = true
                            break
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "⚙ Paramètres types de contrat"
                onClicked: typesSettings.visible = true
            }
        }

        // --- Contenu : une vue à la fois ---
        StackLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            Layout.margins: 8
            currentIndex: root.currentView

            // --- Vue Contrats ---
            DataTable {
                rows: root.contractsData
                columns: [
                    {key: "contract_no",   title: "N° Contrat", width: 130},
                    {key: "client_label",  title: "Client",     width: 190},
                    {key: "contact_name",  title: "Contact",    width: 140},
                    {key: "contract_type", title: "Type",       width: 90},
                    {key: "start_date",    title: "Début",      width: 95},
                    {key: "end_date",      title: "Fin",        width: 95},
                    {key: "cost",          title: "Coût (€)",   width: 85},
                    {key: "status",        title: "Statut",     width: 120},
                ]
                onViewRequested: function(row) {
                    contractDetail.editMode = false
                    contractDetail.loadData(maintBackend.getContract(row.id))
                    contractDetail.visible = true
                }
                onEditRequested: function(row) {
                    contractDetail.editMode = true
                    contractDetail.loadData(maintBackend.getContract(row.id))
                    contractDetail.visible = true
                }
            }

            // --- Vue Clients ---
            DataTable {
                rows: root.clientsData
                columns: [
                    {key: "id",      title: "N° Client", width: 100},
                    {key: "name",    title: "Nom",        width: 250},
                    {key: "id_c4c",  title: "ID C4C",     width: 150},
                ]
                onViewRequested: function(row) {
                    clientDetail.editMode = false
                    clientDetail.loadData(maintBackend.getClient(row.id))
                    clientDetail.visible = true
                }
                onEditRequested: function(row) {
                    clientDetail.editMode = true
                    clientDetail.loadData(maintBackend.getClient(row.id))
                    clientDetail.visible = true
                }
            }

            // --- Vue Contacts ---
            DataTable {
                rows: root.contactsData
                columns: [
                    {key: "last_name",    title: "Nom",         width: 150},
                    {key: "first_name",   title: "Prénom",      width: 150},
                    {key: "email",        title: "Email",       width: 200},
                    {key: "mobile",       title: "Mobile",      width: 130},
                    {key: "client_label", title: "Client",      width: 220},
                ]
                onViewRequested: function(row) {
                    contactDetail.editMode = false
                    contactDetail.loadData(maintBackend.getContact(row.id))
                    contactDetail.visible = true
                }
                onEditRequested: function(row) {
                    contactDetail.editMode = true
                    contactDetail.loadData(maintBackend.getContact(row.id))
                    contactDetail.visible = true
                }
            }

            // --- Vue Machines ---
            DataTable {
                rows: root.machinesData
                columns: [
                    {key: "brand",          title: "Marque",      width: 130},
                    {key: "type",           title: "Type",        width: 130},
                    {key: "reference",      title: "Référence",   width: 130},
                    {key: "build_year",     title: "Année",       width: 75},
                    {key: "location",       title: "Emplacement", width: 150},
                    {key: "contract_label", title: "Contrat",     width: 200},
                ]
                onViewRequested: function(row) {
                    machineDetail.editMode = false
                    machineDetail.loadData(maintBackend.getMachine(row.id))
                    machineDetail.visible = true
                }
                onEditRequested: function(row) {
                    machineDetail.editMode = true
                    machineDetail.loadData(maintBackend.getMachine(row.id))
                    machineDetail.visible = true
                }
            }
        }
    }
}
