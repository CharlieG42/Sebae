import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: disinfectionWindow
    title: "Désinfection"
    width: 1024
    height: 768
    visible: false
    
    MainDisinfection {
        anchors.fill: parent
    }
}