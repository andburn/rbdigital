
function OnPressEnter( arTargetSetting)
{
    $( document).keypress( function ( event)
        {
            event.stopPropagation();
            if ( event.keyCode == 13)
            {
                var calledOn = $( event.target);
                var targetInput;
                for ( var i = 0; i < arTargetSetting.length; i++)
                {
                    var item = arTargetSetting[ i];
                    if ( item.formId == undefined)
                    {
                        targetInput = $( '#'+item.targetInputId);
                        if ( targetInput[ 0] != undefined)
                        {
                            targetInput.click();
                        }
                    }
                    else
                    {
                        targetInput = $( '#'+item.targetInputId);
                        if ( calledOn.parents( '#'+item.formId).length > 0)
                        {
                            targetInput.click();
                        }
                    }
                }
            }
        }
    );
}

String.prototype.trim = function()
{
    //return this.replace( /^\s+|\s+$/g, '');
    return $.trim( this);
};

function OpenPage( strUrl)
{
    window.location = strUrl;
}

//  Bookmark
// http://glamthumbs.com/BookmarkApp.js
function BookmarkHotKeys()
{
    var userAgent = navigator.userAgent.toLowerCase();
    var str = '';
    var bWebkit = ( userAgent.indexOf( 'webkit') != - 1);
    var bMac = ( userAgent.indexOf( 'mac') != - 1);
    var bKonquerur = ( userAgent.indexOf( 'konqueror') != -1);

    if ( bKonquerur)
        str = 'CTRL + B';
    else
    if ( window.home || bWebkit || bMac)
        str = ( bMac ? 'Command/Cmd' : 'CTRL') + ' + D';
    return (( str) ? 'Press ' + str + ' to bookmark this page.' : str);
}
//Code provided by Dynamicdrive
function Bookmark( strTitle, strUrl)
{
    if (window.sidebar) // firefox
        window.sidebar.addPanel( strTitle, strUrl, '');
    else
    if( window.opera && window.print) // opera
    {
        var elem = document.createElement( 'a');
        elem.setAttribute( 'href', strUrl);
        elem.setAttribute( 'title', strTitle);
        elem.setAttribute( 'rel', 'sidebar');
        elem.click();
    }
    else
    if( document.all) // ie
    {
        window.external.AddFavorite( strUrl, strTitle);
        //window.external.AddToFavoritesBar( strUrl, strTitle);
    }
    else
        alert( BookmarkHotKeys());
    return false;
}
// /Bookmark

function Datepiker( strId)
{
    $( '#'+strId).datepicker({});
    $( '#'+strId)[ 0].blur();
    $( '#'+strId)[ 0].focus();
}

function HelpDialog( strId)
{
    $( '#'+strId).dialog({height: 480, width: 640});
}
function RefreshService()
{
    var strUrlPart = $( '#service_t').val();
    if ( strUrlPart == '0')
        OpenPage( $( '#basepath').val()+'all');
    else
        OpenPage( $( '#basepath').val()+strUrlPart);
}

function AddGlobalContent()
{
    $.post( 'ajaxd.php?action=save_global_area'
        , {
            area_id: 'GLOBAL'
            , lib_id: g_nLibraryId
            , content: $( '#content').val()
        }
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    $( '#error').html( data.content);
                }
                else
                if ( data.status == 'ERR')
                {
                    $( '#error').html( data.content);
                }
        }
        , 'json'
    )
}

function ReloadPage( nDelay)
{
    if ( !nDelay)
        nDelay = 10;
    var t = setTimeout( function()
        {
            window.location.reload( true);
        }
        , nDelay
    );
}

// Code provided by http://stackoverflow.com/questions/1403888/get-url-parameter-with-jquery
function GetUrlParameter( strName)
{
    return decodeURIComponent(( RegExp( strName + '=' + '(.+?)(&|$)').exec( window.location.search) || [,null])[1]);
}

function GetUrl()
{
    return window.location.href.replace( /\?.*$/i, '');
}
function GoToHash( strHash)
{
    //window.location.href = location.origin+location.pathname+location.search+'#'+strHash;
    window.location.href = window.location.href.replace( /#.*$/i, '')+'#'+strHash;
}
function GoToHashInDialog()
{
    GoToHash();
    window.scrollTo( 0, 0);
}
function GetHash()
{
    return window.location.hash.substr( 1);
}
function SetHash( strHash)
{
    if ( !strHash)
        var strHash = '';
    window.location.hash = '#'+strHash;
}

function OnShowWarningList()
{
    if ( $( '#warning-event-header').hasClass( 'active'))
    {
        $( '#warning-event-list').slideToggle( 'slow'
            , function()
            {
                $( '#warning-event-header').toggleClass( 'active');
            }
        );
    }
    else
    {
        $( '#warning-event-list').slideToggle( 'slow');
        $( '#warning-event-header').toggleClass( 'active');
    }
}

function OnHideWarningEvent()
{
    $( '#warning-event-block').hide();
    var date = new Date( new Date().getTime() + 86400000); // 24h
    CookiesManagerSetCookie( 'stop_warning_event', 'MQ==', date.toUTCString(), '/');
}

// Google Analytics
{
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-38081881-1', 'rbdigital.com');
    ga('send', 'pageview');
}

var g_nLibraryId = 0;