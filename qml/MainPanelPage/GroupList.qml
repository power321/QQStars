import QtQuick 2.2
import mywindow 1.0
import utility 1.0

Item{
    id: friendlist_main
    clip:true
    width: parent.width
    height: parent.height
    function getGroupListFinished( error, data ) {
        if(error){
            myqq.getGroupList(getGroupListFinished) //获取群列表
            return
        }
        
        data = JSON.parse(data)
        if(data.retcode ==0 ) {
            var groupmarknames = data.result.gmarklist//群备注信息
            for( var i=0; i<groupmarknames.length;++i ) {
                myqq.setValue("group"+groupmarknames[i].uin+"alias", groupmarknames[i].markname)//储存备注信息
            }
            var list_info = data.result.gnamelist
            mymodel.append({"obj_name": "群", "obj_listData": JSON.stringify(list_info) })
        }
    }
    function getDiscusListFinished(error, data) {//获取讨论组列表完成
        if(error){
            myqq.getDiscusList(getDiscusListFinished) //讨论组列表
            return
        }
        
        data = JSON.parse(data)
        if(data.retcode ==0 ) {
            var list_info = data.result.dnamelist
            mymodel.append({"obj_name": "讨论组", "obj_listData": JSON.stringify(list_info)})
        }
    }
    Component.onCompleted: {
        myqq.getGroupList(getGroupListFinished) //获取群列表
        myqq.getDiscusList(getDiscusListFinished) //讨论组列表
    }

    MyScrollView{
        anchors.fill: parent
        Item{
            height: list.contentHeight+10
            width: friendlist_main.width
            implicitHeight: height
            implicitWidth: width
            ListView{
               id: list
               interactive: false
               anchors.fill: parent
               model: ListModel{
                   id:mymodel
               }
               spacing :10
               delegate: component1
            }
        }
    }
    Component{
        id: component1
        Item{
            id: root
            clip: true
            property string name: obj_name
            property var list_data: JSON.parse(obj_listData)
            onList_dataChanged: {
                for( var i=0; i< list_data.length;++i ) {
                    model.append({"obj_info": list_data[i]})
                }
            }

            property alias model: mymodel2
            height: text_name.implicitHeight
            width: parent.width
            
            state: "close"
            function stateSwitch(){
                if( state=="close" )
                    state = "unfold"
                else
                    state="close"
            }
        
            states: [
                State {
                    name: "close"
                    PropertyChanges {
                        target: root
                        height: text_name.implicitHeight
                    }
                },
                State {
                    name: "unfold"
                    PropertyChanges {
                        target: root
                        height: text_name.implicitHeight+list2.contentHeight+10
                    }
                }
            ]
            
            Text{
                id: image_icon
                x:10
                anchors.verticalCenter: text_name.verticalCenter
                text: root.state == "close"?"+":"-"
                font.pointSize: 16
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        root.stateSwitch()
                    }
                }
            }
        
            Text{
                id: text_name
                text: name
                anchors.left: image_icon.right
                anchors.leftMargin: 10
                font.pointSize: 10
                font.bold: true
            }
        
            ListView{
                id: list2
                model: ListModel{
                    id:mymodel2
                }
                interactive: false
                spacing: 10
                delegate: component2
                anchors.top: text_name.bottom
                anchors.topMargin: 10
                width: parent.width
                height: parent.height
            }
        }
    }
    Component{
        id: component2
        Item{
            width: parent.width
            height: avatar.height
            property var info: obj_info
            property int type
            property string uin: {
                if( info.gid ){
                    type = QQ.Group
                    myqq.setValue("group"+info.gid+"nick", info.name)
                    return info.gid
                }else{
                    type = QQ.Discu
                    myqq.setValue("group"+info.did+"nick", info.name)
                    return info.did
                }
            }
            property string account: myqq.getValue("group"+uin+"account", "")//真实的群号
            
            function getQQFinished(error, data){//获取真实群号后调用的函数
                if(error){
                    myqq.getFriendQQ(info.code, getQQFinished)
                    return
                }

                data = JSON.parse(data)
                if( data.retcode==0 ){
                    account = data.result.account
                    console.log(myqq.getValue("group"+uin+"nick", info.name)+"的真实QQ是："+account+","+info.code+","+uin)
                    myqq.setValue("group"+uin+"account", account)//保存真实qq
                    if( avatar.source=="qrc:/images/avatar.png" )//如果头像不存在
                        myqq.downloadImage("http://p.qlogo.cn/gh/"+account+"/"+account+"/40", "group"+account, "40", getAvatarFinished)//下载头像
                }
            }
            function getAvatarFinished( path ,name){
                var imageName = path+"/"+name+".png"
                myqq.setValue("group"+uin+name, imageName)//保存头像的地址
                avatar.source = imageName
            }

            Component.onCompleted: {
                //console.log(myqq.getValue("group"+uin+"nick", info.name)+"的真实QQ是："+account)
                if( type == QQ.Group ){
                    if(account==""){
                        myqq.getFriendQQ(info.code, getQQFinished)
                    }else{
                        if( avatar.source=="qrc:/images/avatar.png" )//如果头像不存在
                            myqq.downloadImage("http://p.qlogo.cn/gh/"+account+"/"+account+"/40", "group"+account, "40", getAvatarFinished)//下载头像
                    }
                }
            }

            MyImage{
                id: avatar
                x:10
                width:40
                maskSource: "qrc:/images/bit.bmp"
                source: myqq.getValue("group"+parent.uin+"avatar-40", "qrc:/images/avatar.png")
                onLoadError: {
                    avatar.source = "qrc:/images/avatar.png"
                }
            }
            Text{
                id:text_nick
                anchors.top: avatar.top
                anchors.left: avatar.right
                anchors.leftMargin: 10
                font.pointSize: 14
                text: myqq.getValue("group"+parent.uin+"alias", info.name)
            }
            MouseArea{
                anchors.fill: parent
                onDoubleClicked: {
                    chat_command.addChat(parent.uin, parent.type)
                }
            }
        }
    }
}
