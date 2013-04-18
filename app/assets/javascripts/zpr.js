function zpr(viewFinderId, inputValues) {
  
  var viewFinder = $('#' + viewFinderId); // viewFinder DOM element
  var imgFrame   = undefined; // for imgFrame DOM element
  var imgFrameId = viewFinderId + "-img-frame";
  
  var settings = {
    tileSize: 512,            // dimension for a square tile 
    marqueeImgSize: 125,      // max marquee dimension (should be > 50)
    preloadTilesOffset: 0,    // rows/columns of tiles to preload
    djatokaBaseResolution: 92 // djatoka JP2 base resolution for levels
  };  
  
  var errors = [];    
  var currentLevel = 1;
  var currentRotation = 0;
  
  var jp2 = { width: 0, height: 0, levels: undefined, imgURL: undefined }   
  var imgFrameAttrs = { relativeLoc: {}, proportionalWidth: 0, proportionalHeight: 0 };
  var marqueeAttrs = { imgWidth: 0, imgHeight: 0, width: 0, height: 0 }; 

  /* init() function */
  function init() {
    // validate and store input values
    storeInputValues(inputValues);
    
    // if there are input value errors, display them and quit
    if (errors.length > 0) {
      renderErrors();
      return;
    }
        
    // create and attach 'imgFrame' element to 'viewFinder'
    viewFinder
      .addClass('zpr-view-finder')
      .append($('<div>', { 'id': imgFrameId, 'class': 'zpr-img-frame' }));        
      
    imgFrame = $('#' + imgFrameId);    
    currentLevel = getLevelForContainer(viewFinder.width(), viewFinder.height());
    
    if (typeof inputValues.zoomIncrement !== 'undefined') {
        currentLevel = util.clampLevel(currentLevel + inputValues.zoomIncrement);
        hasZoomIncrement = true;
    }

    setImgFrameSize(currentLevel);
    setupImgFrameDragging();
    storeRelativeLocation();
    addControlElements();
    if (hasZoomIncrement) centerImgFrame();
  }


  /* validate mandatory and optional input values, and store them locally */
  function storeInputValues(inputValues) {                
    // store jp2 width from input values
    if (util.isValidLength(inputValues.width)) {
      jp2.width = parseInt(inputValues.width, 10);
    } else {
      errors.push('Error: Input width is empty or not valid');
    }
    
    // store jp2 height from input values
    if (util.isValidLength(inputValues.height)) {
      jp2.height = parseInt(inputValues.height, 10);
    } else {
      errors.push('Error: Input height is empty or not valid')
    }

    // store image stacks URL from input values
    if (util.isValid(inputValues.imageStacksURL)) {
      jp2.imgURL = inputValues.imageStacksURL.toString();
    } else {
      errors.push('Error: Input Image Stacks URL is empty or not valid');
    }    
    
    // store jp2 levels from input values (optional argument)
    if (util.isValidLength(inputValues.levels)) {
      jp2.levels = parseInt(inputValues.levels, 10);
    } else {
      jp2.levels = getNumLevels();
    }

    // store marquee size from input values (optional argument)
    if (util.isValidLength(inputValues.marqueeImgSize)) {
      settings.marqueeImgSize = parseInt(inputValues.marqueeImgSize, 10);
    }
  }
  
  /* render input errors to page */
  function renderErrors() {
    var errorBlock = $('<div></div>').addClass('zpr-error');
    
    $.each(errors, function(index, error) {
      errorBlock
        .append(error + '</br>');
    });
    
    if (errors.length > 0) {
      viewFinder.append(errorBlock);
    }    
  }
  
  
  /* add zoom and other controls */
  function addControlElements() {    
    // add zoom/rotate controls
    viewFinder
    .append($('<div>').attr({ 'class': 'zpr-controls' })
      .append($('<img>')
        .attr({ 'id': viewFinderId + '-zoom-in', 'src': 'data:image/png;base64,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'})
        .click(function() { zoom('in'); }))
      .append($('<img>')
        .attr({ 'id': viewFinderId + '-zoom-out', 'src': 'data:image/png;base64,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' })
        .click(function() { zoom('out'); }))
      .append($('<img>')
        .attr({ 'id': viewFinderId + '-rotate-cw', 'src': 'data:image/png;base64,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' })
        .click(function() { rotate('cw'); }))
      .append($('<img>')
        .attr({ 'id': viewFinderId + '-rotate-ccw', 'src': 'data:image/png;base64,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' })
        .click(function() { rotate('ccw'); }))
    );
    
    setupMarquee();
  }  
    
  
  /* get total levels for the jp2 */
  function getNumLevels() {
    var longestSide = Math.max(jp2.width, jp2.height);
    var level = 0;
    
    while (longestSide > settings.djatokaBaseResolution) {
      longestSide = Math.round(longestSide / 2);
      level += 1;
    }
        
    return level;
  }

  
  /* set imgFrame dimensions */
  function setImgFrameSize(level) {    
    imgFrame.width(getImgDimensionsForLevel(level)[0]);    
    imgFrame.height(getImgDimensionsForLevel(level)[1]);

    imgFrameAttrs.proportionalWidth  = Math.round(jp2.width / Math.pow(2, jp2.levels - currentLevel));
    imgFrameAttrs.proportionalHeight = Math.round(jp2.height / Math.pow(2, jp2.levels - currentLevel));
    
    setMarqueeDimensions();    
    positionImgFrame();   
  }

  
  /* get dimensions for a given level */
  function getImgDimensionsForLevel(level) {
    var divisor = Math.pow(2, (jp2.levels - level));
    var height  = Math.round(jp2.height / divisor);    
    var width   = Math.round(jp2.width / divisor);
    
    return ([width, height]);    
  }
  
  
  /* calculate level for a given container */
  function getLevelForContainer(ctWidth, ctHeight) {
    var jp2Width  = jp2.width;
    var jp2Height = jp2.height;
    var level = jp2.levels;
    
    if (!util.isValidLength(ctHeight)) {
      ctHeight = ctWidth;
    }
        
    while (level >= 0) {
      if (ctWidth >= jp2Width && ctHeight >= jp2Height) {
        return util.clampLevel(level);        
      }
      
      jp2Width  = Math.round(jp2Width / 2);
      jp2Height = Math.round(jp2Height / 2);
      level -= 1;      
    }  
      
    return 0;
  }
  
  
  /* position imgFrame */
  function positionImgFrame() {
    var left = 0;
    var top = 10;
    
    if (imgFrame.width() < viewFinder.width()) {     
      left = Math.floor((viewFinder.width() / 2) - (imgFrame.width() / 2));
      
      if (imgFrame.height() < viewFinder.height()) {
        top = Math.floor((viewFinder.height() / 2) - (imgFrame.height() / 2));
      }
    } 

    // if relative location is defined, use it to position imgFrame
    if (typeof imgFrameAttrs.relativeLoc.x !== 'undefined' && 
        typeof imgFrameAttrs.relativeLoc.y !== 'undefined') {
    
       left = Math.round(viewFinder.width() / 2) - Math.ceil(imgFrameAttrs.relativeLoc.x * imgFrame.width());        
       top = Math.round(viewFinder.height() / 2) - Math.ceil(imgFrameAttrs.relativeLoc.y * imgFrame.height());        
    }    

    imgFrame.css({ 'top': top + 'px', 'left': left + 'px' });
    showTiles(); 
  }
  
  
  /* get list of visible tiles */
  function getVisibleTiles() {
    var visibleImgSpace = { left: 0, top: 0, right: 0, bottom: 0 };
    var visibleTileIds  = { leftmost: 0, topmost: 0, rightmost: 0, bottommost: 0 };
    var numVisibleTiles = { x: 0, y: 0 };
    var totalTiles      = { x: 0, y: 0 };

    var visibleTileArray = [];
    var ctr = 0;
    var tileSize = settings.tileSize;
    
    // total available tiles for imgFrame 
    totalTiles.x = Math.ceil(imgFrame.width() / tileSize);
    totalTiles.y = Math.ceil(imgFrame.height() / tileSize);
    
    // calculate visibleImgSpace location
    if (imgFrame.position().left > 0) {
      visibleImgSpace.left = imgFrame.position().left;
    }
        
    if (imgFrame.position().top > 0) {
      visibleImgSpace.top = imgFrame.position().top;
    }
    
    visibleImgSpace.right  = Math.min(imgFrame.position().left + imgFrame.width(), viewFinder.width());
    visibleImgSpace.bottom = Math.min(imgFrame.position().left + imgFrame.height(), viewFinder.height());
    
    // total tiles visible in viewFinder
    numVisibleTiles.x = Math.ceil((visibleImgSpace.right - visibleImgSpace.left) / tileSize) + 1;
    numVisibleTiles.y = Math.ceil((visibleImgSpace.bottom - visibleImgSpace.top) / tileSize) + 1;
        
    if (imgFrame.position().left < 0) {
      visibleTileIds.leftmost = Math.abs(Math.ceil(imgFrame.position().left / tileSize));
    }

    if (imgFrame.position().top < 0) {
      visibleTileIds.topmost = Math.abs(Math.ceil(imgFrame.position().top / tileSize));
    }
    
    visibleTileIds.rightmost  = visibleTileIds.leftmost + numVisibleTiles.x;
    visibleTileIds.bottommost = visibleTileIds.topmost + numVisibleTiles.y;
    
    // preload/cache extra tiles for better user experience
    visibleTileIds.leftmost   -= settings.preloadTilesOffset;
    visibleTileIds.topmost    -= settings.preloadTilesOffset;
    visibleTileIds.rightmost  += settings.preloadTilesOffset;
    visibleTileIds.bottommost += settings.preloadTilesOffset;
    
    // validate visible tile ids
    visibleTileIds.leftmost   = Math.max(visibleTileIds.leftmost, 0);
    visibleTileIds.topmost    = Math.max(visibleTileIds.topmost, 0);    
    visibleTileIds.rightmost  = Math.min(visibleTileIds.rightmost, totalTiles.x);
    visibleTileIds.bottommost = Math.min(visibleTileIds.bottommost, totalTiles.y);
    
    for (var x = visibleTileIds.leftmost; x < visibleTileIds.rightmost; x += 1) {          
      for (var y = visibleTileIds.topmost; y < visibleTileIds.bottommost; y += 1) {
        visibleTileArray[ctr] = [x, y];
        ctr += 1;
      }
    }
        
    return visibleTileArray;
  }
  
  
  /* add tiles to the imgFrame */
  function showTiles() {
    var visibleTiles = getVisibleTiles();
    var visibleTilesMap = [];
    var multiplier = Math.pow(2, jp2.levels - currentLevel);
    var tileSize = settings.tileSize;
    
    // prepare each tile and add it to imgFrame
    for (var i = 0; i < visibleTiles.length; i += 1) {
      var attrs = { x: visibleTiles[i][0], y: visibleTiles[i][1] };      
      var xTileSize, yTileSize;
      var angle = parseInt(currentRotation, 10);
      var tile = undefined;
      
      var insetValueX = attrs.x * tileSize;
      var insetValueY = attrs.y * tileSize;        
      
      attrs.id = 'tile-x' + attrs.x + 'y' + attrs.y + 'z' + currentLevel + 'r' + currentRotation + '-' + viewFinderId;      
      attrs.src = 
        jp2.imgURL + '.jpg?zoom=' + util.getZoomFromLevel(currentLevel) + 
        '&region=' + insetValueX + ',' + insetValueY + ',' + tileSize + ',' + tileSize + '&rotate=' + currentRotation;
      
      visibleTilesMap[attrs.id] = true; // useful for removing unused tiles       
      tile = $('#' + attrs.id);
                        
      if (tile.length == 0) {
        tile = $(document.createElement('img'))        
               .css({ 'position': 'absolute' })
               .attr({ 'id': attrs.id, 'src': attrs.src });
    
        distanceX = (attrs.x * tileSize) + 'px';
        distanceY = (attrs.y * tileSize) + 'px';     
        
        if (angle === 90) {
          tile.css({ 'right': distanceY, 'top': distanceX });
        } else if (angle === 180) {
          tile.css({ 'right': distanceX, 'bottom': distanceY });
        } else if (angle === 270) {
          tile.css({ 'left': distanceY, 'bottom': distanceX });
        } else {
          tile.css({ 'left': distanceX, 'top': distanceY });
        }
        
        imgFrame.append(tile);
      }      
    }
    
    removeUnusedTiles(visibleTilesMap);
    storeRelativeLocation();
    drawMarquee();    
  }
  
  
  /* remove unused tiles to save memory */
  function removeUnusedTiles(visibleTilesMap) {    
    imgFrame.find('img').each(function(index) {
      if (/^tile-x/.test(this.id) && !visibleTilesMap[this.id]) {
        $('#' + this.id).remove();       
        //console.log('removing ' + this.id); 
      }       
    });    
  }
  
  
  /* setup zoom controls */
  function zoom(direction) {
    var newLevel = currentLevel;

    if (direction === 'in') {
      newLevel = util.clampLevel(newLevel + 1); 
    } else if (direction === 'out') {
      newLevel = util.clampLevel(newLevel - 1); 
    }

    if (newLevel !== currentLevel) {
      currentLevel = newLevel;
      setImgFrameSize(currentLevel);
    }
  }
  

  /* setup rotate controls */
  function rotate(direction) {
    var newRotation = currentRotation;
    var angle = 90;

    if (direction === 'cw') {
      newRotation = currentRotation + 90;         
    } else if (direction === 'ccw') {
      newRotation = currentRotation - 90;
      angle = -90;      
    }
    
    if (newRotation < 0) { newRotation += 360; }
    if (newRotation >= 360) { newRotation -= 360; }
    
    if (newRotation !== currentRotation) {
      currentRotation = newRotation;
      swapJp2Dimensions();
      swapRelativeLocationValues(angle);
      setImgFrameSize(currentLevel);
      setupMarquee();
    }
  }


  /* for rotate actions, swap jp2 dimensions */
  function swapJp2Dimensions() {
    var tmpWidth = jp2.width;
    
    jp2.width = jp2.height;
    jp2.height = tmpWidth; 
  }


  /* for rotate actions, swap relative location values based on given value */ 
  function swapRelativeLocationValues(angle) {
    var tmpX = imgFrameAttrs.relativeLoc.x;
    
    if (parseInt(angle, 10) > 0) {
      imgFrameAttrs.relativeLoc.x = 1 - imgFrameAttrs.relativeLoc.y;
      imgFrameAttrs.relativeLoc.y = tmpX;
    } else {
      imgFrameAttrs.relativeLoc.x = imgFrameAttrs.relativeLoc.y;
      imgFrameAttrs.relativeLoc.y = 1 - tmpX;      
    }
  }

  
  /* store imgFrame relative location - for positioning after zoom/rotate */
  function storeRelativeLocation() {
    
    imgFrameAttrs.relativeLoc.x = 
      (Math.round((viewFinder.width() / 2) - imgFrame.position().left) / imgFrame.width()).toFixed(2);
            
    imgFrameAttrs.relativeLoc.y = 
      (Math.round((viewFinder.height() / 2) - imgFrame.position().top) / imgFrame.height()).toFixed(2);    
    //console.log('relative loc: ' + imgFrameAttrs.relativeLoc.x + ',' + imgFrameAttrs.relativeLoc.y);
  }
  
  
  /* setup mouse events for imgFrame dragging */
  function setupImgFrameDragging() {    
    var attrs = {
      isDragged: false, 
      left: 0,
      top: 0,
      drag: { left: 0, top: 0 },
      start: { left: 0, top: 0 },
    };
 
    imgFrame.bind({
      mousedown: function(event) {        
        if (!event) { event = window.event; } // required for IE
        
        attrs.drag.left = event.clientX;
        attrs.drag.top  = event.clientY;
        attrs.start.left = imgFrame.position().left;
        attrs.start.top  = imgFrame.position().top;
        attrs.isDragged  = true;         

        imgFrame.css({ 'cursor': 'default', 'cursor': '-moz-grabbing', 'cursor': '-webkit-grabbing' });
           
        return false;
      },
      
      mousemove: function(event) {
        if (!event) { event = window.event; } // required for IE
        
        if (attrs.isDragged) {
          attrs.left = attrs.start.left + (event.clientX - attrs.drag.left);      
          attrs.top = attrs.start.top + (event.clientY - attrs.drag.top);
  
          imgFrame.css({
            'left': attrs.left + 'px',
            'top': attrs.top + 'px'
          });
                    
          showTiles();        
        }        
      }      
    });

    imgFrame.ondragstart = function() { return false; } // for IE    
    $(document).mouseup(function() { stopImgFrameMove();  });

    function stopImgFrameMove() {
      attrs.isDragged = false;      
      imgFrame.css({ 'cursor': '' });
    }        
  }
  
  
  /* setup mouse events for marquee dragging */
  function setupMarqueeDragging() {
    var marqueeBgId = viewFinderId + '-marquee-bg';    
    var marqueeId = viewFinderId + '-marquee';        
    
    var attrs = {
      isDragged: false, 
      left: 0,
      top: 0,
      drag: { left: 0, top: 0 },
      start: { left: 0, top: 0 },
    };
 
    var marquee = $('#' + marqueeId);   
 
    marquee.bind({
      mousedown: function(event) {        
        if (!event) { event = window.event; } // required for IE
        
        attrs.drag.left = event.clientX;
        attrs.drag.top  = event.clientY;
        attrs.start.left = marquee.position().left;
        attrs.start.top  = marquee.position().top;
        attrs.isDragged  = true;         

        marquee.css({
          'cursor': 'default', 
          'cursor': '-moz-grabbing',
          'cursor': '-webkit-grabbing'          
        });
           
        return false;
      },
      
      mousemove: function(event) {
        var maxLeft, maxTop;
        
        if (!event) { event = window.event; } // required for IE
        
        if (attrs.isDragged) {
          attrs.left = attrs.start.left + (event.clientX - attrs.drag.left);      
          attrs.top = attrs.start.top + (event.clientY - attrs.drag.top);
  
          // limit marquee dragging to within the marquee background image
          maxLeft = marqueeAttrs.imgWidth - marquee.width();
          maxTop  = marqueeAttrs.imgHeight - marquee.height();
  
          // validate positioning values
          if (attrs.left < 0) { attrs.left = 0; } 
          if (attrs.top < 0) { attrs.top = 0; } 
          
          if (attrs.left > maxLeft) { attrs.left = maxLeft; }
          if (attrs.top > maxTop) { attrs.top = maxTop; }
          
          marquee.css({
            'left': attrs.left + 'px',
            'top': attrs.top + 'px'
          });                    
        }        
      }      
    });

    marquee.ondragstart = function() { return false; } // for IE    
    //$(document).mouseup(function() { stopMarqueeMove();  });
    marquee.mouseup(function() { stopMarqueeMove();  });

    function stopMarqueeMove() {
      attrs.isDragged = false;      
      marquee.css({ 'cursor': '' });

      imgFrameAttrs.relativeLoc.x = ((marquee.position().left + (marquee.width() / 2)) / marqueeAttrs.imgWidth).toFixed(2);
      imgFrameAttrs.relativeLoc.y = ((marquee.position().top + (marquee.height() / 2)) / marqueeAttrs.imgHeight).toFixed(2);
      positionImgFrame();      
    }            
  }
  
  
  /* setup marquee box, background image and marquee  */
  function setupMarquee() {
    var level = util.clampLevel(getLevelForContainer(settings.marqueeImgSize) + 1);
    var marqueeBoxId = viewFinderId + '-marquee-box';
    var marqueeBgId = viewFinderId + '-marquee-bg';    
    var marqueeId = viewFinderId + '-marquee';        
    var minMarqueeImgSize = 50;
    var marqueeURL;
    
    // if marquee image size is too small, it becomes unusable. So, don't render it
    if (settings.marqueeImgSize < minMarqueeImgSize) {
      return;
    }
    
    // remove marquee if already present
    if ($('#' + marqueeBoxId).length != 0) {
      $('#' + marqueeBoxId).remove();
    }
    
    storeRelativeLocation();
    setMarqueeImgDimensions();
             
    marqueeURL = jp2.imgURL + '.jpg?w=' + marqueeAttrs.imgWidth + '&h=' + marqueeAttrs.imgHeight + '&rotate=' + currentRotation;   
      
    viewFinder
    .append($('<div>', { 'id': marqueeBoxId, 'class': 'zpr-marquee-box' })
      .append($('<div>', { 'id': marqueeBgId }))    
    );    
      
    // append marquee to div with marquee background image  
    $('#' + marqueeBgId)
    .css({
      'height': (marqueeAttrs.imgHeight + 4) + 'px', // 4 = marquee border  
      'width':  (marqueeAttrs.imgWidth + 4) + 'px', // 4 = marquee border
      'position': 'relative', 
      'background': '#fff url(\'' + marqueeURL + '\')  no-repeat center center'  
    })
    .append($('<div>', { 
      'id': marqueeId, 
      'class': 'zpr-marquee'      
    }));
        
    setupMarqueeDragging();
    drawMarquee();
  }


  /* draw marquee and position it */
  function drawMarquee() {    
    var left = Math.ceil((imgFrameAttrs.relativeLoc.x * marqueeAttrs.imgWidth) - (marqueeAttrs.width / 2));
    var top = Math.ceil((imgFrameAttrs.relativeLoc.y * marqueeAttrs.imgHeight) - (marqueeAttrs.height / 2));
    
    $('#' + viewFinderId + '-marquee').css({
      'left': left + 'px',
      'top': top + 'px',
      'height': marqueeAttrs.height + 'px',
      'width': marqueeAttrs.width + 'px'                  
    });
  }


  /* set initial marquee dimensions */
  function setMarqueeImgDimensions() {
    var aspectRatio = (jp2.width / jp2.height).toFixed(2);

    marqueeAttrs.imgWidth  = Math.round(settings.marqueeImgSize * aspectRatio);                  
    marqueeAttrs.imgHeight = settings.marqueeImgSize;
       
    if (aspectRatio > 1) {
      marqueeAttrs.imgWidth  = settings.marqueeImgSize;
      marqueeAttrs.imgHeight = Math.round(settings.marqueeImgSize / aspectRatio);            
    }
    
    setMarqueeDimensions();
  }  
    
  function setMarqueeDimensions() {
    marqueeAttrs.width  = Math.ceil((viewFinder.width() / imgFrameAttrs.proportionalWidth) * marqueeAttrs.imgWidth) - 4;
    marqueeAttrs.height = Math.ceil((viewFinder.height() / imgFrameAttrs.proportionalHeight) * marqueeAttrs.imgHeight) - 4;    
  }

  /* utility functions */
  var util = {
    // clamp jp2 level between 0 and max level 
    clampLevel: function(level) {
      if (level < 0) { level = 0; }
      if (level > jp2.levels) { level = jp2.levels; }    
      return level;
    },
    
    // get image stacks zoom value (0 to 100) for a level
    getZoomFromLevel: function(level) {
      var zoom = 0;
      
      level = util.clampLevel(level);
      zoom = (100 / Math.pow(2, jp2.levels - currentLevel)).toFixed(5);
      
      return zoom;
    },    
    
    // check if value is defined
    isValid: function(value) {
      return (typeof value !== 'undefined');
    },
    
    // check if value is a valid length (positive number > 0)
    isValidLength: function(value) {
      if (typeof value !== 'undefined') {
        value = parseInt(value, 10);
        
        if (value > 0) {
          return true;    
        }
      } 
      
      return false;
    }
  };
  
  init();
}
