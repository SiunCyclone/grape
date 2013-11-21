$(function(){
  // { target: string, names: [string], children: [], childnames: {} }
  var root = [];
  var decls = {};
  var count = 0;

  function register($decl) {
    var $parent = $decl.parent().closest('.decl');
    var list = ($parent.length == 0) ? root : register($parent);
    var id = $decl.attr('id');

    if (!id) {
      id = 'dc_' + (++count);
      $decl.attr('id', id);

      var names = [];
      $decl.find('.target:first').siblings('.target').andSelf().each(function(){
        names.push($(this).text());
      });

      // constructor is not recognized as a symbol
      if (names.length == 0) names = ['this'];

      var data = {
        target: '#' + id,
        names: names,
        children: [],
        childnames: {}
      };

      list.push(data);
      decls[id] = data;

      $decl.parents('.decl').each(function(){
        var childnames = decls[$(this).attr('id')].childnames;
        for (var i=0; i<names.length; ++i) {
          childnames[names[i]] = id;
        }
      });
    }

    return list[list.length-1].children;
  }

  function findDeclName($decl, name) {
    if ($decl.length == 0) return '#';

    var data = decls[$decl.attr('id')];

    for (var i=0; i<data.names.length; ++i) {
      if (data.names[i] == name) return data.target;
    }

    if (data.childnames[name]) {
      return decls[data.childnames[name]].target;
    }

    return findDeclName($decl.parent().closest('.decl'), name);
  }

  function treeMenu(decls) {
    var ret = '<ul>';

    for (var i=0; i<decls.length; ++i) {
      var decl = decls[i];

      ret += '<li><a href="' + decl.target + '">';
      for (var j=0; j<decl.names.length; ++j) {
        if (j != 0) {
          if (decl.names[j] == decl.names[j-1]) continue;
          ret += '</a></li><li><a href="' + decl.target + '">';
        }
        ret += decl.names[j];
      }
      ret += '</a>';
      if (decl.children.length) ret += treeMenu(decl.children);
      ret += '</li>';
    }

    ret += '</ul>';
    return ret;
  }

  $('.decl').each(function(){ register($(this)); });

  $('.jump').each(function(){
    var $this = $(this);
    $this.attr('href', findDeclName($this.closest('.decl'), $this.text()));
  });

  $('.menu').append(treeMenu(root));
  $('.menu').find('li').each(function(){
    $(this).addClass($(this).children('ul').length ? "dir" : "file");
  });
  $('.menu').on('click', 'a', function(){
    $(this).parent().children('ul').each(function(){
      var $ul = $(this);
      if ($ul.css('display') == 'block') {
        $(this).css('display', 'none');
        $(this).parent().removeClass('open');
      } else {
        $(this).css('display', 'block');
        $(this).parent().addClass('open');
      }
    });
  });

  $('.menu a:first').click();
});

