import bb.cascades 1.2
import bb.data 1.0
import bb 1.0
import "tart.js" as Tart

NavigationPane {
    id: newPage
    property variant theModel: theModel
    property alias loading: loading.visible
    property string whichPage: ""
    property string morePage: ""
    property string errorText: ""
    property string lastItemType: ""
    property string readerURL: "http://www.readability.com/m?url="
    property bool busy: false

    onCreationCompleted: {
        Tart.register(newPage)
    }

    onPopTransitionEnded: {
        page.destroy();
        Application.menuEnabled = ! Application.menuEnabled;
    }

    onPushTransitionEnded: {
        if (page.objectName == 'commentPage') {
            Tart.send('requestPage', {
                    source: page.commentLink,
                    sentBy: 'commentPage',
                    askPost: page.isAsk,
                    deleteComments: "False"
                });
        }
    }

    function onAddnewStories(data) {
        morePage = data.moreLink;
        errorLabel.visible = false;
        var lastItem = theModel.size() - 1
        //console.log("LAST ITEM: " + lastItemType);
        if (lastItemType == 'error' || lastItemType == 'load') {
            theModel.removeAt(lastItem)
        }
        theModel.append({
                type: 'item',
                title: data.story['title'],
                domain: data.story['domain'],
                points: data.story['score'],
                poster: data.story['author'],
                timePosted: data.story['time'],
                commentCount: data.story['commentCount'],
                articleURL: data.story['link'],
                commentsURL: data.story['commentURL'],
                hnid: data.story['hnid'],
                isAsk: data.story['askPost']
            });
        lastItemType = 'item'
        busy = false;
        loading.visible = false;
        titleBar.refreshEnabled = ! busy;
    }

    function onNewListError(data) {
        if (theModel.isEmpty() != true) {
            var lastItem = theModel.size() - 1
            //console.log(lastItemType);
            if (lastItemType == 'error' || lastItemType == 'load') {
                theModel.removeAt(lastItem)
            }
            theModel.append({
                    type: 'error',
                    title: data.text
                });
        } else {
            errorLabel.text = data.text
            errorLabel.visible = true;
        }
        lastItemType = 'error'
        busy = false;
        loading.visible = false;
        titleBar.refreshEnabled = ! busy;
    }

    function showSpacer() {
        if (errorLabel.visible == true || loading.visible == true) {
            return true;
        } else {
            return false;
        }
    }
    Page {
        titleBar: HNTitleBar {

            id: titleBar
            text: "Reader YC - Newest"
            listName: theList
            onRefreshPage: {
                console.log("We are busy: " + busy)
                if (busy != true) {
                    busy = true;
                    Tart.send('requestPage', {
                            source: 'newestPage',
                            sentBy: 'newestPage'
                        });
                    console.log("pressed")
                    theModel.clear();
                    refreshEnabled = ! busy;
                    loading.visible = true;
                }
            }
        }
        Container {
            layout: DockLayout {
            }
            Container {
                visible: errorLabel.visible
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                Label {
                    textStyle.base: lightStyle.style
                    id: errorLabel
                    text: "<b><span style='color:#ff7900'>Error getting stories</span></b>\nCheck your connection and try again!"
                    textStyle.fontSize: FontSize.PointValue
                    textStyle.textAlign: TextAlign.Center
                    textStyle.fontSizeValue: 9
                    textStyle.color: Color.DarkGray
                    textFormat: TextFormat.Html
                    multiline: true
                    visible: false
                }
            }
            Container {
                visible: loading.visible
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                ActivityIndicator {
                    id: loading
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    minHeight: 300
                    minWidth: 300
                    running: true
                    visible: true
                }
            }
            Container {
                ListView {
                    id: theList
                    dataModel: ArrayDataModel {
                        id: theModel
                    }
                    function itemType(data, indexPath) {
                        return data.type;
                    }
                    listItemComponents: [
                        ListItemComponent {
                            type: 'item'
                            HNPage {
                                property string type: ListItemData.type
                                postComments: ListItemData.commentCount
                                postTitle: ListItemData.title
                                postDomain: ListItemData.domain
                                postUsername: ListItemData.poster
                                postTime: ListItemData.timePosted + "| " + ListItemData.points
                                postArticle: ListItemData.articleURL
                                askPost: ListItemData.isAsk
                                commentSource: ListItemData.commentsURL
                                commentID: ListItemData.hnid
                            }
                            function openComments(ListItemData) {
                                var page = commentPage.createObject();
                                console.log(ListItemData.commentsURL)
                                page.commentLink = ListItemData.hnid;
                                page.title = ListItemData.title;
                                page.titlePoster = ListItemData.poster;
                                page.titleTime = ListItemData.timePosted + "| " + ListItemData.points;
                                page.titleDomain = ListItemData.domain;
                                page.isAsk = ListItemData.isAsk;
                                page.articleLink = ListItemData.articleURL;
                                page.titleComments = ListItemData.commentCount;
                                page.titlePoints = ListItemData.points
                                newPage.push(page);
                            }
                            function openArticle(ListItemData) {
                                var page = webPage.createObject();
                                page.htmlContent = ListItemData.articleURL;
                                if (settings.readerMode == true && ListItemData.isAsk != "true")
                                    page.htmlContent = readerURL + ListItemData.articleURL;
                                page.text = selectedItem.title;
                                newPage.push(page);
                            }

                        },
                        ListItemComponent {
                            type: 'error'
                            ErrorItem {
                                id: errorItem
                            }
                        },
                        ListItemComponent {
                            type: 'load'
                            LoadItem {
                                id: loadItem
                                horizontalAlignment: HorizontalAlignment.Center
                                verticalAlignment: VerticalAlignment.Center
                                property string type: ListItemData.type
                            }
                        }
                    ]
                    onTriggered: {
                        if (dataModel.data(indexPath).type != 'item') {
                            return;
                        }

                        var selectedItem = dataModel.data(indexPath);
                        if (settings.openInBrowser == true) {
                            // will auto-invoke after re-arming
                            console.log("OPENING IN BROWSER");
                            linkInvocation.query.uri = "";
                            linkInvocation.query.uri = selectedItem.articleURL;
                            return;
                        }
                        if (settings.readerMode == true && selectedItem.isAsk != "true") {
                            selectedItem.articleURL = readerURL + selectedItem.articleURL;
                            console.log('Item triggered. ' + selectedItem.articleURL);
                            var page = webPage.createObject();
                            page.htmlContent = selectedItem.articleURL;
                            page.text = selectedItem.title;
                            newPage.push(page);
                            return;
                        }
                        console.log(selectedItem.isAsk);
                        if (selectedItem.isAsk == "true") {
                            console.log("Ask post");
                            var page = commentPage.createObject();
                            console.log(selectedItem.commentsURL)
                            page.commentLink = selectedItem.hnid;
                            page.title = selectedItem.title;
                            page.titlePoster = selectedItem.poster;
                            page.titleTime = selectedItem.timePosted;
                            page.titleDomain = selectedItem.domain;
                            page.isAsk = selectedItem.isAsk;
                            page.articleLink = selectedItem.articleURL;
                            page.titleComments = selectedItem.commentCount;
                            page.titlePoints = selectedItem.points
                            newPage.push(page);
                        } else {
                            console.log('Item triggered. ' + selectedItem.articleURL);
                            var page = webPage.createObject();
                            page.htmlContent = selectedItem.articleURL;
                            page.text = selectedItem.title;
                            newPage.push(page);
                        }
                    }
                    attachedObjects: [
                        ListScrollStateHandler {
                            onAtEndChanged: {
                                if (atEnd == true && theModel.isEmpty() == false && morePage != "" && busy == false) {
                                    console.log('end reached!');
                                    var lastItem = theModel.size() - 1;
                                    if (lastItemType == 'load') {
                                        return;
                                    }
                                    if (lastItemType == 'error') { // Remove an error item
                                        theModel.removeAt(lastItem);
                                    }
                                    theModel.append({
                                            type: 'load'
                                        });
                                    //theList.scrollToPosition(ScrollPosition.End, ScrollAnimation.Smooth);
                                    lastItemType = 'load';
                                    Tart.send('requestPage', {
                                            source: morePage,
                                            sentBy: whichPage
                                        });
                                    busy = true;
                                }
                            }
                        }
                    ]
                }
            }
        }

        attachedObjects: [
            TextStyleDefinition {
                id: lightStyle
                base: SystemDefaults.TextStyles.BodyText
                fontSize: FontSize.PointValue
                fontSizeValue: 7
                fontWeight: FontWeight.W100
            },
            Invocation {
                id: linkInvocation
                property bool auto_trigger: false
                query {
                    uri: "http://peterhansen.ca"
                    invokeTargetId: "sys.browser"

                    onUriChanged: {
                        if (uri != "") {
                            linkInvocation.query.updateQuery();
                        }
                    }
                }

                onArmed: {
                    // don't auto-trigger on initial setup
                    if (auto_trigger)
                        trigger("bb.action.OPEN");
                    auto_trigger = true; // allow re-arming to auto-trigger
                }
            },
            ComponentDefinition {
                id: webPage
                source: "webArticle.qml"
            },
            ComponentDefinition {
                id: commentPage
                source: "CommentPage.qml"
            },
            ComponentDefinition {
                id: userPage
                source: "UserPage.qml"
            }
        ]
    }
}