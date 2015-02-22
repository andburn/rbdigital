$( document).ready
(
  function()
  {
    $( document).click( OnDocumentClick);
    if ( window.onpopstate)
      window.onpopstate = function(){InitSearch();};
    else
      InitSearch();    
  }
);

function OnDocumentClick( event)
{
  switch ( event.target.id)
  {
    case 'suggest_bar':
    case 'title_search_line':
    {
      break;
    }
    default :
    {
      TitleSearch();
      break;
    }
  }
}
function AddHistory( strQuery)
{
  if ( window.history.pushState)
    window.history.pushState( 0, 'Zinio Page Search', GetUrl()+'?'+strQuery);
  else
    OpenPage( GetUrl()+'?'+strQuery);
}
function OnCancelSearch()
{
  OpenPage( GetUrl());
}
function ChangePageRelationForSearch()
{
  var strText = $( '#zinio_collection_title').html();
  if ( strText.search( 'Search Results') == -1)
    $( '#zinio_collection_title').html( '<a href="#" onclick="OnCancelSearch(); return false;">Zinio Magazine Collection</a> &gt; Search Results');
}

var s_strTitleSearchLabel = false;
var s_strTitleSearchQuery = false;
var s_strGenreSearchQuery = false;
function LoadContent( strTitleSerachQuery, strGenreSearchQuery)
{
  if ( !strTitleSerachQuery)
    var strTitleSerachQuery = '';
  if ( !strGenreSearchQuery)
    var strGenreSearchQuery = '';
  $.post( 'ajaxd.php?action=zinio_landing_search'
    , {
        title_search_line: strTitleSerachQuery
        , genre_search_line: strGenreSearchQuery
        , lib_id: g_nLibraryId
      }
    , function ( data)
      {
        if ( data)
        if ( data.status == 'OK')
          $( '#collection_pages').replaceWith( $.base64.decode( data.content));
      }
    , 'json'
    );
}
function InitSearch()
{
  s_strTitleSearchLabel = $( '#title_search_line').val();
  $.post( 'ajaxd.php?action=zinio_landing_search_suggest'
    , {
        title_search_line: ''
        , genre_search_line: ''
        , lib_id: g_nLibraryId
      }
    , function ( data)
      {
        if ( data)
        if ( data.status == 'OK')
        {
          $( '#suggest_bar').html( $.base64.decode( data.content));
          var strQuery = GetUrlParameter( 'q');
          var strMode = GetUrlParameter( 'mode');
          if ( strQuery != 'null')
          {
            if ( strMode != 'null')
            {
              $( '#genre_search_line').val( strQuery);
              GenreSearch( true);
            }
            else
            {
              $( '#title_search_line').val( strQuery);
              TitleSearch( true);
            }
          }
          else
          if ( $( '#collection_pages').find( 'div.magazine_detail').length == 0)
            LoadContent();
        }
      }
    , 'json'
    ) 
}
function Search( strTitleSearchQuery, strGenreSearchQuery)
{
  RestorePageRelation();
  ChangePageRelationForSearch();
  LoadContent( strTitleSearchQuery, strGenreSearchQuery);
}
function DropTitleSearch( bDoNotDropHistory)
{
  $( '#title_search_line').val( s_strTitleSearchLabel);
  if ( !bDoNotDropHistory)
    s_strTitleSearchQuery = '';  
}
function TitleSearch( bFirstCall)
{
  $( '#suggest_bar').hide();

  var strTitleSearchQuery = $( '#title_search_line').val().trim();
  var strTitleSearchQueryHostory = strTitleSearchQuery;
  if ( strTitleSearchQuery == s_strTitleSearchLabel)
  {
    strTitleSearchQueryHostory = '';
    strTitleSearchQuery = '';
  }
  if ( strTitleSearchQuery.length == 1)
    strTitleSearchQuery = 'exact:'+strTitleSearchQuery+'%';

  if ( s_strTitleSearchQuery != strTitleSearchQuery)
  {
    s_strTitleSearchQuery = strTitleSearchQuery;
    DropGenreSearch();
    if ( !bFirstCall)
      AddHistory( 'q='+encodeURIComponent( strTitleSearchQueryHostory));
    Search( strTitleSearchQuery);
  }  
}
function DropGenreSearch()
{
  $( '#genre_search_line').val( '');
  s_strGenreSearchQuery = '';
}
function GenreSearch( bFirstCall)
{
  var strGenreSearchQuery = $( '#genre_search_line').val().trim();
  strGenreSearchQuery = 'exact:'+strGenreSearchQuery;
  if ( s_strGenreSearchQuery != strGenreSearchQuery)
  {
    s_strGenreSearchQuery = strGenreSearchQuery;
    DropTitleSearch();
    if ( !bFirstCall)
      AddHistory( 'q='+encodeURIComponent( $( '#genre_search_line').val())+'&mode=1');
    Search( false, strGenreSearchQuery);
  }  
}
function OnSuggestItem( caller)
{
  $( '#title_search_line').val( $( caller).text());
  TitleSearch();
}
function SearchSuggest()
{
  var strTitleSearchQuery = $( '#title_search_line').val().trim();
  if ( strTitleSearchQuery.length > 0)
  {
    var bFound = false;
    $.each( $( '#suggest_bar ul li'), function()
    {
      var self = $( this);
      var strValue = self.text().trim();
      if ( strTitleSearchQuery.length == 1)
      {
        if ( strValue.match( /^The /i))
          strValue = strValue.substring( 4, 5);
        else
          strValue = strValue.substring( 0, 1);
      }

      if ( strValue.toLowerCase().indexOf( strTitleSearchQuery.toLowerCase()) !== -1)
      {
        bFound = true;
        self.show();
      }
      else
        self.hide();
    });

    if ( bFound)
      $( '#suggest_bar').show();
    else
      $( '#suggest_bar').hide();
  }
  else
  {
    if ( $( '#suggest_bar ul li').length > 0)
    {      
      $( '#suggest_bar ul li').show();
      $( '#suggest_bar').show();
    }
  }
  
  //$( '#suggest_bar').scroll( 0);
  // bugfix (scrollTop + IE scroll bug)
  $( '#suggest_bar').replaceWith( $( '#suggest_bar').clone());
}
function OnTitleSearchKeyDown( event)
{
  if ( event.keyCode == 13)
    TitleSearch();
  else
    var t = setTimeout( SearchSuggest, 100);
}
function OnTitleSearchFocus()
{
  if ( $( '#title_search_line').val().trim() == s_strTitleSearchLabel)
    $( '#title_search_line').val( '');
  var t = setTimeout( SearchSuggest, 100);
}
function OnTitleSearchLooseFocus()
{
  if ( $( '#title_search_line').val().trim() == '')
    DropTitleSearch( true);
}

function OnPage( strId)
{
  $( '.collection_page').removeClass( 'selected');
  $( '#'+strId).addClass( 'selected');

  $( '#'+strId+' .magazine img').each(function()
  {
    if ( !$( this).attr( 'src'))
      $( this).attr( 'src', $( this).attr( 'data'));
  });
}

function ShowZinioCheckoutDialog( strTitle)
{
  $( '#zinio_checkout_dialog').dialog({ height: 'auto'
                            , width: 620
                            , modal: true
                            , position: ['center', 200]
                            , title: strTitle
                            , close: function()
                            {
                              //if ( !s_bPreventLoginDialogClear)
                              {
                                $( '#zinio_checkout_dialog').html('');
                                //s_bPreventLoginDialogClear = false;
                              }
                              Refresh();
                            }
                            });
}
function LoadZinioCheckoutDialogData()
{
  LoadDialogData( 'zinio_checkout_dialog');
}
function CloseZinioCheckoutDialog()
{
  var t = setTimeout( function()
                    {
                      $( '#zinio_checkout_dialog').dialog( 'close');
                    }
                    , 10
                    );  
}

function OnCheckout( nId, bBackIssue)
{
  if ( bBackIssue)
  {
    var request = { lib_id: g_nLibraryId
                  , issue_id: nId
                  };
  }
  else
  {
    var request = { lib_id: g_nLibraryId
                  , mag_id: nId
                  };
  }
  $.post( 'ajaxd.php?action=zinio_checkout'
    , request
    , function ( data)
      {
        if ( data)
        if ( data.status == 'OK')
        {
          $( '#zinio_checkout_dialog').html( $.base64.decode( data.content));
        }
        else
        {
          if ( data.cmd == 'LOGIN')
          {
            g_loginAwaitingAction = function (){ OnCheckout( nId, bBackIssue)};
            CloseZinioCheckoutDialog();
            ToLogin();
          }
          else
            $( '#zinio_checkout_dialog').html( $.base64.decode( data.content));
        }
      }
    , 'json'
    );
  LoadZinioCheckoutDialogData();
  ShowZinioCheckoutDialog( 'Complete your checkout');
}

function OnCompleteCheckout( nId, bBackIssue, bAgressiveMode)
{
  if ( bBackIssue)
  {
    var request = { lib_id: g_nLibraryId
                    , issue_id: nId
                    , mode: bAgressiveMode ? 1 : 0
                  };
  }
  else
  {
    var request = { lib_id: g_nLibraryId
                    , mag_id: nId
                  };
  }
  $.post( 'ajaxd.php?action=zinio_checkout_complete'
    , request
    , function ( data)
      {
        if ( data)
        if ( data.status == 'OK')
        {
          ShowZinioCheckoutDialog( data.title);
          $( '#zinio_checkout_dialog').html( $.base64.decode( data.content));
          Redirect( 3000);
        }
        else
        if ( data.cmd == 'LOGIN')
        {
          g_loginAwaitingAction = function (){ OnCompleteCheckout( nId, bBackIssue, bAgressiveMode)};
          CloseZinioCheckoutDialog();
          ToLogin();
        }
        else
        {
          ShowZinioCheckoutDialog( data.title);
          $( '#zinio_checkout_dialog').html( '<strong>' + $.base64.decode( data.content) + '</strong>');
        }

      }
    , 'json'
    );
  LoadZinioCheckoutDialogData();
  ShowZinioCheckoutDialog( 'Checking out...');
}

function OnCancelBackIssues()
{
  RestorePageRelation();
  $( '#collection_pages').html( s_strCollectionHtmlTempStore);
  s_bBackIssueMode = false;
}


function RestorePageRelation()
{
  var strText = $( '#zinio_collection_title').html();
  $( '#zinio_collection_title').html( 'Zinio Magazine Collection');
  if ( strText.search( 'Search Results') != -1)
    ChangePageRelationForSearch();
}

function ChangePageRelationForBackIssues( strMagazineName)
{
  var strText = $( '#zinio_collection_title').html();
  var strTitle = strMagazineName+' Back issues';
  if ( strText.search( 'Search Results') == -1)
  {
    $( '#zinio_collection_title').html( strText.replace( 'Zinio Magazine Collection'
                                      , '<a href="#" onclick="OnCancelBackIssues(); return false;">Zinio Magazine Collection</a> &gt; '
                                        +strTitle
                                        )
                                      );
  }
  else
  {
    $( '#zinio_collection_title').html( strText.replace( 'Search Results'
                                      , '<a href="#" onclick="OnCancelBackIssues(); return false;">Search Results</a> &gt; '
                                        +strTitle
                                        )
                                      );
  }
}

var s_strCollectionHtmlTempStore = '';
var s_bBackIssueMode = false;
function OnBackIssuesClick( nMagazineId)
{
  RestorePageRelation();
  ChangePageRelationForBackIssues( $( '#mag_'+nMagazineId).text());
  
  if ( !s_bBackIssueMode)
    s_strCollectionHtmlTempStore = $( '#collection_pages').html();
  $( '#collection_pages').html( $( '#issue_collection_pages_'+nMagazineId).html());
  
  OnPage( 'p_issue_'+nMagazineId+'1');

  s_bBackIssueMode = true;
}

function OnBackIssuesDetailPageClick( nMagazineId)
{
  $( '#back_issues_detail_page').html( $( '#issue_collection_pages_'+nMagazineId).html());
  OnPage( 'p_issue_'+nMagazineId+'1');
}
