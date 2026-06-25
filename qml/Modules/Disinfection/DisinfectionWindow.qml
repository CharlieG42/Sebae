import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
