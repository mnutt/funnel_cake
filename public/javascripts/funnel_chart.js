/*
 * FunnelChart class
 * - for drawing a funnel-style chart for conversion visualization
 */
function FunnelChart(_element, _funnel_nodes, _settings){
    var self = this;
    this.element = _element;
    this.funnel_nodes = _funnel_nodes;
    this.settings = _settings;
    this.labels = [];
    
    var onLoad = function(){
        self.onWindowLoad();
    };
    if (window.addEventListener) {
        window.addEventListener("load", onLoad, false);
    }
    else 
        if (window.attachEvent) {
            window.attachEvent("onload", onLoad);
        }
}

FunnelChart.prototype = {
    getLoaded: function(){
        return this.windowLoaded;
    },
    onWindowLoad: function(e){
        this.windowLoaded = true;
        this.initCanvas();
    },
    initCanvas: function(){
        if (!this.ctx && this.getLoaded()) {
            // IE recreates the element?
            this.canvas = this.element.getElementsByTagName("canvas")[0];
            this.ctx = this.canvas.getContext("2d");
            
            if (!this.ctx) {
                return;
            }
            this.layout();
        }
    },
    layout: function(){
        this.padding = 20.0;
        
        for (k in this.settings) {
            this[k] = this.settings[k];
        }
        this.width = this.canvas.width - (2.0 * this.padding);
        this.canvasHeight = this.canvas.height;
        
        this.preloadImages(); //this will call drawWithImages() when the images are loaded
        this.drawBeforeImages();
    },
	 redraw: function(){
	 	this.ctx.clearRect(0,0,10000,10000);
		this.labels.each(function(l){l.remove()});
		this.labels = [];
		this.layout();
	 },
    drawBeforeImages: function(){
        for (var i = 0; i < this.funnel_nodes.length - 1; i++) {
            var node = this.funnel_nodes[i];
            var nextNode = this.funnel_nodes[i + 1];
            var lineargradient = this.ctx.createLinearGradient(this.padding, node.position.y, this.width - this.padding, node.position.y);
            lineargradient.addColorStop(0, '#3060BF');
            lineargradient.addColorStop(0.5, '#FFFFFF');
            lineargradient.addColorStop(1, '#60B0BF');
            this.ctx.fillStyle = lineargradient;
            this.ctx.strokeStyle = '#3060BF';
            this.ctx.lineWidth = 1;
            this.ctx.beginPath();
            console.debug(node.position);
            this.ctx.moveTo(this.padding, node.position.y + node.size.height);
            this.ctx.lineTo(this.width - this.padding, node.position.y + node.size.height);
            this.ctx.lineTo(this.width / 2.0 + 10, nextNode.position.y);
            this.ctx.lineTo(this.width / 2.0 - 10, nextNode.position.y);
            this.ctx.lineTo(this.padding, node.position.y + node.size.height);
            this.ctx.fill();
            this.ctx.stroke();
        }
		  this.drawLabels();
    },
    preloadImages: function(){
        this.preloaded_images = 0;
        var self = this;
        
        //this.least.image = new Image(); // Create new Image object          
        //this.least.image.onload = function(){
        //    self.imageLoadedCallback();
        //};
        //this.least.image.src = this.least.src;
    },
    imageLoadedCallback: function(){
        this.preloaded_images++;
        //if (this.preloaded_images == this.cards.length + 2) {
        //}
        this.drawWithImages();
    },
    drawWithImages: function(){
	 },
    drawLabels: function(){	 
        for (var i = 0; i < this.funnel_nodes.length - 1; i++) {
            var node = this.funnel_nodes[i];
            var nextNode = this.funnel_nodes[i + 1];
            var pos = {
                x: this.width / 2.0 - node.size.width / 2.0,
                y: node.position.y
            };
            this.addLabel(node.name, pos, node.size, 'funnel_node_label');

            pos = {
                x: this.width / 2.0 - 100.0 / 2.0,
                y: node.position.y + (nextNode.position.y - node.position.y)/3.0
            };
            this.addLabel(node.rate, pos, {width: 100, height: 70}, 'funnel_rate_label');
        }
    },
    addLabel: function(text, position, size, classname){
        var label = new Element('div', {
            'class': classname
        });
		  label.setStyle({
		  		top: position.y+this.element.positionedOffset().top+'px',
				left: position.x+this.element.positionedOffset().left+'px',
				width: size.width+'px',
				height: size.height+'px',
				position: 'absolute',
				textAlign: 'center',
				fontSize: '13px',
				marginTop: '5px'			
		  });
		  console.debug(label.style);
        label.update(text);
        this.labels.push(label);
        this.element.insert(label);
    }
};
