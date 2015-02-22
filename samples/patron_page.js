$( document).ready
(
    function()
    {
        if ( GetHash() == 'open_plrp')
        {
            ToResetPassword();
            SetHash();
        }
        OnPressEnter( new Array( { targetInputId: 'pl_login'}
                , { targetInputId: 'pl_create_account'}
                , { targetInputId: 'pl_forgot_p'}
                , { targetInputId: 'pl_next'}
                , { targetInputId: 'pl_reset_p'}
            )
        );

        $( '#jplayer_player_1').jPlayer({
            ready: function ()
            {
                $( this).jPlayer( 'setMedia'
                    , { m4v: $( '#jplayer_src_1').text()
                        , poster: $( '#jplayer_poster_1').text()
                    }
                );
            }
            , loadstart: function ()
            {
                $( '#jplayer_loader_1').css( 'display', 'block');
            }
            , loadedmetadata: function ()
            {
                $( '#jplayer_loader_1').hide();
            }
            , smoothPlayBar: true
            , preload: 'auto'
            , solution: 'html,flash'
            , supplied: 'm4v'
            , swfPath: 'js/jplayer/'
            , volume: 0.8
            , muted: false
            , backgroundColor: '#000000'
            , cssSelectorAncestor: '#jplayer_container_1'
        });

        $( '#toggler_tutorial').hide();
    }
);

var g_loginAwaitingAction = false;
var s_bPreventLoginDialogClear = false;

function Redirect( nDelay)
{
    if ( !nDelay)
        var nDelay = 1000;
    var strHref = $( '#redirect').attr( 'href');
    if ( strHref)
        if ( strHref != '')
            var t = setTimeout( 'window.location = \''+strHref+'\';', nDelay);
}
function Refresh( bStartLoginAwaitingAction)
{
    if ( $( '#refresh')[ 0])
    {
        if ( g_loginAwaitingAction != false)
        {
            if ( bStartLoginAwaitingAction)
                g_loginAwaitingAction();
            else
                ReloadPage();
        }
        else
            ReloadPage();
    }
}

function ShowLoginDialog( strTitle)
{
    $( '#login_dialog').dialog({ height: 'auto'
        , width: 480
        , modal: true
        , title: strTitle
        , close: function()
        {
            if ( !s_bPreventLoginDialogClear)
            {
                $( '#login_dialog').html('');
                s_bPreventLoginDialogClear = false;
            }
        }
    });
}
function LoadDialogData( strDialogId)
{
    $( '#'+strDialogId).html( $( '#dialog_loading').html());
}
function LoadLoginDialogData()
{
    LoadDialogData( 'login_dialog');
}

function ToLogin()
{
    $.post( 'ajaxd.php?action=p_login'
        , { lib_id: g_nLibraryId
        }
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    $( '#login_dialog').html( $.base64.decode( data.content));
                }
        }
        , 'json'
    );
    LoadLoginDialogData();
    ShowLoginDialog( 'Log in');

}
function ToCreateAccount()
{
    var nAccessKeyInGetParam = 0;
    var strAccessKey = GetUrlParameter( 'access_key');

    var params = { lib_id: g_nLibraryId
        , ref: decodeURIComponent( CookiesManagerGetCookie( 'ref'))//document.referrer
    };
    if ( strAccessKey != 'null')
    {
        params = { lib_id: g_nLibraryId
            , access_key: strAccessKey
            , in_get_param: nAccessKeyInGetParam
            , ref: decodeURIComponent( CookiesManagerGetCookie( 'ref'))//document.referrer
        };
    }

    $.post( 'ajaxd.php?action=patron_registration'
        , params
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    $( '#login_dialog').html( $.base64.decode( data.content));
                    Redirect();
                }
        }
        , 'json'
    );
    LoadLoginDialogData();
    ShowLoginDialog( 'Create New Account');
}
function ToResetPassword()
{
    $.post( 'ajaxd.php?action=p_reset_password'
        , { lib_id: g_nLibraryId
            , email: $( '#email_reset').val()
            , t: GetUrlParameter( 't')
            , password: $( '#password').val()
            , r_password: $( '#r_password').val()
        }
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    $( '#login_dialog').html( $.base64.decode( data.content));
                    if ( data.title != '')
                        ShowLoginDialog( data.title);
                }
        }
        , 'json'
    );
    LoadLoginDialogData();
    ShowLoginDialog( 'Reset Your Password');
}

function OnLogOut()
{
    $.post( 'ajaxd.php?action=p_logout'
        , {}
        , function ( data)
        {
            ReloadPage();
        }
    );
}
function OnLogIn()
{
    $.post( 'ajaxd.php?action=p_login'
        , { lib_id: g_nLibraryId
            , email: $( '#email').val()
            , password: $( '#password').val()
            , remember_me: $( '#remember_me')[ 0].checked?1:0
        }
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    if ( data.cmd == 'REFRESH')
                    {
                        s_bPreventLoginDialogClear = true;
                        $( '#login_dialog').dialog( 'close');
                        $( '#login_dialog').html( $.base64.decode( data.content));
                        Refresh( true);
                    }
                    else
                        $( '#login_dialog').html( $.base64.decode( data.content));

                }
        }
        , 'json'
    );
    LoadLoginDialogData();
    ShowLoginDialog( 'Log in');
}
function OnRegistrate()
{
    $.post( 'ajaxd.php?action=patron_registration'
        , {
            email: $( '#email').val()
            , password: $( '#password').val()
            , r_password: $( '#r_password').val()
            , pname: $( '#pname').val()
            , plname: $( '#plname').val()
            , lib_id: g_nLibraryId
            , ref: decodeURIComponent( CookiesManagerGetCookie( 'ref'))//document.referrer
            , access_key: $( '#access_key').val()
            , pbcode: $( '#pbcode').val()
            , patron: $( '#patron').val()
            , patron_pwd: $( '#patron_pwd').val()
        }
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    if ( data.cmd == 'REFRESH')
                    {
                        s_bPreventLoginDialogClear = true;
                        $( '#login_dialog').dialog( 'close');
                        $( '#login_dialog').html( $.base64.decode( data.content));
                        Refresh( true);
                    }
                    else
                        $( '#login_dialog').html( $.base64.decode( data.content));
                }
        }
        , 'json'
    );
    LoadLoginDialogData();
    ShowLoginDialog( 'Create New Account');
}

function JoinService( strServiceKey)
{
    $.post( 'ajaxd.php?action=p_service_join'
        , {
            lib_id: g_nLibraryId
            , service_t: strServiceKey
        }
        , function ( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                    $( '#hidden_action').html( $.base64.decode( data.content));
                    $( '#hidden_form').submit();
                }
                else
                {
                    if ( data.cmd == 'LOGIN')
                    {
                        g_loginAwaitingAction = function (){ JoinService( strServiceKey)};
                        ToLogin();
                    }
                    else if ( data.cmd == 'ERR')
                    {
                        $( '#error_dialog').html( $.base64.decode( data.content));
                        $( '#error_dialog').dialog({ height: 'auto'
                            , width: 400
                            , modal: true
                        });
                    }
                    else
                    {
                        $( '#login_dialog').html( $.base64.decode( data.content));
                        ShowLoginDialog( 'Service Join');
                    }
                }
        }
        , 'json'
    );
}

function OnWatchTutorial()
{
    $( '#toggler_tutorial').toggle( 'slow');
}

function SavePatronSetting( strKey, strValue, callback, bAsync)
{
    if ( !bAsync)
        bAsync = false;

    $.ajax({ url: 'ajaxd.php?action=set_patron_setting'
        , type: 'POST'
        , async: bAsync
        , data: { lib_id: g_nLibraryId
            , patron_setting_key: strKey
            , patron_setting_value: strValue
        }
    }).done( function( data)
        {
            if ( data)
                if ( data.status == 'OK')
                {
                }

            if ( callback)
                callback( data);
            setTimeOut( 'ReloadPage', 200);
        }
        , 'json'
    );
}
function DisclaimerDoNotShowAgain( caller, strKey, callback)
{
    if ( $( caller).is( ':checked'))
        SavePatronSetting( strKey, 1, callback, true);
    else
    if ( callback)
        callback();
}
function DisclaimerClose( strDialogId)
{
    $( '#'+strDialogId).dialog( 'close');
}
function DisclaimerOk( strDialogId
    , strDoNotShowAgainId
    , strDoNotShowAgainKey
    , doNotShowAgainCallback
    , bPlainUrl
    )
{
    var bAnswer = false;
    var callback = function ()
    {
        if ( !bPlainUrl)
        {
            $( '#hidden_form').prop( 'onsubmit', null);
            $( '#hidden_form').submit();
        }
        DisclaimerClose( strDialogId);
    }
    if ( strDoNotShowAgainId)
    {
        DisclaimerDoNotShowAgain( $( '#'+strDoNotShowAgainId)
            , strDoNotShowAgainKey
            , function ( data)
            {
                if ( data)
                    if ( doNotShowAgainCallback)
                        doNotShowAgainCallback( data, strDialogId);
                callback();
            }
        );
    }
    else
        callback();
    if ( bPlainUrl)
        bAnswer = true;
    return bAnswer;
}
function DisclaimerCancel( strDialogId)
{
    DisclaimerClose( strDialogId);
    return false;
}
function DisclaimerOpen( strDialogId, bStatic)
{
    var parentNode = $( '#'+strDialogId).parent();
    var node = $( '#'+strDialogId).clone();
    $( '#'+strDialogId).dialog({ width: 550
        , modal: true
        , appendTo: '#'+parentNode.id
        , close: function()
        {
            if ( g_loginAwaitingAction)
                setTimeout( 'Refresh();', 500);
            setTimeout( function ()
                {
                    $( '#'+strDialogId).remove();
                    parentNode.append( node);
                }
                , 100
            );
        }
    });
    return false;
}