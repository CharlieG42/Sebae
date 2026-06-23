// Func.qml — Fonctions utilitaires (collecte des champs, appels backend)
import QtQuick

Item {

    function exportPDF() {
        var _pump1 = {
            name:     pump1.currentText,
            year:     years1.currentText,
            hours:    hours1.value,
            flowrate: flowrate1.value,
            head:     head1.value,
            pumpEff:  pumpEff1.value,
            motorEff: motorEff1.value,
            cost:     cost1.value
        }
        var _pump2 = {
            name:     pump2.currentText,
            year:     years2.currentText,
            hours:    hours2.value,
            flowrate: flowrate2.value,
            head:     head2.value,
            pumpEff:  pumpEff2.value,
            motorEff: motorEff2.value,
            cost:     cost2.value
        }
        var _title = salesRep.currentText + " - " + project.currentText
        backend.getValues(_pump1, _pump2, _title, customer.currentText,
                          energyCost.value, co2.value)
        return true
    }

    function saveProject() {
        var _pump1 = {
            name:     pump1.currentText,
            year:     years1.currentText,
            hours:    hours1.value,
            flowrate: flowrate1.value,
            head:     head1.value,
            pumpEff:  pumpEff1.value,
            motorEff: motorEff1.value,
            cost:     cost1.value
        }
        var _pump2 = {
            name:     pump2.currentText,
            year:     years2.currentText,
            hours:    hours2.value,
            flowrate: flowrate2.value,
            head:     head2.value,
            pumpEff:  pumpEff2.value,
            motorEff: motorEff2.value,
            cost:     cost2.value
        }
        var _project = {
            PUMP1:     JSON.stringify(_pump1),
            PUMP2:     JSON.stringify(_pump2),
            NAME:      project.currentText,
            SALES_REP: salesRep.currentText,
            CUSTOMER:  customer.currentText,
            NRJ_COST:  energyCost.value,
            CO2_COEF:  co2.value
        }
        backend.addValue("T_PROJECTS", _project)
        return true
    }
}
