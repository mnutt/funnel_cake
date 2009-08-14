/*
 * FunnelChart class
 * - for drawing a funnel-style chart for conversion visualization
 */
function FunnelChart(_selector, _settings) {
	var self = this;
	this.selector = _selector;
	this.settings = _settings;
};
FunnelChart.prototype = {
	draw: function(){
		var self = this;
		$$(this.selector).each(function(wrapper_elem){

			// Grab container element
			var element = wrapper_elem.down('.funnel_stage_container');

			// Initialize Canvas
			var canvas = $(element).getElementsByTagName("canvas")[0];
			if (!canvas) {
				canvas = new Element('canvas', {
					'width': element.getWidth(),
					'height': element.getHeight(),
					'id': element.id + '_canvas'
				});
			  canvas.setStyle({
					border: '0',
					padding: '0'
			  });
				element.insert(canvas, {position: 'top'});
			}
		  var ctx = canvas.getContext("2d");

			// Init values from settings
			var width = (self.settings && self.settings.width) ? self.settings.width : element.getWidth();
			var padding = (self.settings && self.settings.padding) ? self.settings.padding : 0;

			// Draw Gradient Funnel
			var lineargradient = ctx.createLinearGradient(padding, 0, width - padding, 0);
			lineargradient.addColorStop(0, '#3088D0');
			lineargradient.addColorStop(0.5, '#FFFFFF');
			lineargradient.addColorStop(1, '#60B0BF');
			ctx.fillStyle = lineargradient;
			ctx.strokeStyle = '#3060BF';
			ctx.lineWidth = 1;
			ctx.beginPath();
			ctx.moveTo(padding, 0);
			ctx.lineTo(width - padding, 0);
			ctx.lineTo(width / 2.0 + 10, element.getHeight());
			ctx.lineTo(width / 2.0 - 10, element.getHeight());
			ctx.lineTo(padding, 0);
			ctx.fill();
			ctx.stroke();

			// Position the labels inside
			var label = element.down('.funnel_rate_label');
			if (label) {
	      var labelpos = {
	          x: 0,
	          y: (element.getHeight())/3.5
	      };
			  label.setStyle({
		  		top: labelpos.y + element.positionedOffset().top + 'px',
					left: labelpos.x + element.positionedOffset().left + 'px',
					width: width + 'px',
					position: 'absolute'
			  });
			}

			// Position the spinner
			var label = wrapper_elem.down('.spinner');
			if (label) {
	      var labelpos = {
	          x: element.getWidth()/2 - 10,
	          y: (element.getHeight() - padding)/3.5
	      };
			  label.setStyle({
		  		top: labelpos.y + element.positionedOffset().top + 'px',
					left: labelpos.x + element.positionedOffset().left + 'px',
					position: 'absolute'
			  });
			}
		});
	},

	refreshData: function(date_range_start, date_range_end) {
		$$(this.selector).each(function(e){
			var states = e.id.replace(/funnel_stage_/,'');
			var top_state = states.split(/-/)[0];
			var bottom_state = states.split(/-/)[1];

			e.down('.spinner').appear({duration: 0.25});
			new Ajax.Request('funnel_stage',
				{
					asynchronous:true,
					evalScripts:true,
					method:'get',
					parameters: {
						authenticity_token: '<%=escape_javascript(form_authenticity_token)%>',
						state: top_state,
						next_state: bottom_state,
						date_range_start: date_range_start,
						date_range_end: date_range_end
					}
				}
			);
		});
	}

};

//
//
// function FunnelChart(_element, _funnel_nodes, _settings){
//     var self = this;
//     this.element = _element;
//     this.funnel_nodes = _funnel_nodes;
//     this.settings = _settings;
//     this.labels = [];
// }
//
// FunnelChart.prototype = {
//     initCanvas: function(){
//         if (!this.ctx) {
//             this.canvas = this.element.getElementsByTagName("canvas")[0];
//             this.ctx = this.canvas.getContext("2d");
//
//             if (!this.ctx) {
//                 return;
//             }
//             this.layout();
//         }
//     },
//     layout: function(){
//         this.padding = 20.0;
//
//         for (k in this.settings) {
//             this[k] = this.settings[k];
//         }
//         this.width = this.canvas.width - (2.0 * this.padding);
//         this.canvasHeight = this.canvas.height;
//
//         this.preloadImages(); //this will call drawWithImages() when the images are loaded
//         this.drawBeforeImages();
//     },
// 	 redraw: function(){
// 			if (!this.ctx) {
// 				this.initCanvas();
// 			}
// 	 	this.ctx.clearRect(0,0,10000,10000);
// 		this.labels.each(function(l){l.remove()});
// 		this.labels = [];
// 		this.layout();
// 	 },
//     drawBeforeImages: function(){
//         for (var i = 0; i < this.funnel_nodes.length - 1; i++) {
//             var node = this.funnel_nodes[i];
//             var nextNode = this.funnel_nodes[i + 1];
//             var lineargradient = this.ctx.createLinearGradient(this.padding, node.position.y, this.width - this.padding, node.position.y);
//             lineargradient.addColorStop(0, '#3088D0');
//             lineargradient.addColorStop(0.5, '#FFFFFF');
//             lineargradient.addColorStop(1, '#60B0BF');
//             this.ctx.fillStyle = lineargradient;
//             this.ctx.strokeStyle = '#3060BF';
//             this.ctx.lineWidth = 1;
//             this.ctx.beginPath();
//             this.ctx.moveTo(this.padding, node.position.y + node.size.height);
//             this.ctx.lineTo(this.width - this.padding, node.position.y + node.size.height);
//             this.ctx.lineTo(this.width / 2.0 + 10, nextNode.position.y);
//             this.ctx.lineTo(this.width / 2.0 - 10, nextNode.position.y);
//             this.ctx.lineTo(this.padding, node.position.y + node.size.height);
//             this.ctx.fill();
//             this.ctx.stroke();
//         }
// 		  this.drawLabels();
//     },
//     preloadImages: function(){
//         this.preloaded_images = 0;
//         var self = this;
//
//         //this.least.image = new Image(); // Create new Image object
//         //this.least.image.onload = function(){
//         //    self.imageLoadedCallback();
//         //};
//         //this.least.image.src = this.least.src;
//     },
//     imageLoadedCallback: function(){
//         this.preloaded_images++;
//         //if (this.preloaded_images == this.cards.length + 2) {
//         //}
//         this.drawWithImages();
//     },
//     drawWithImages: function(){
// 	 },
//     drawLabels: function(){
//         for (var i = 0; i < this.funnel_nodes.length; i++) {
//             var node = this.funnel_nodes[i];
//             var nextNode = this.funnel_nodes[i + 1];
//             var pos = {
//                 x: this.width / 2.0 - node.size.width / 2.0,
//                 y: node.position.y
//             };
//             this.addLabel(node.name, pos, node.size, 'funnel_node_label', 'funnel_node_'+node.id);
//
// 						if (nextNode) {
// 	            pos = {
// 	                x: this.width / 2.0 - 100.0 / 2.0,
// 	                y: node.position.y + (nextNode.position.y - node.position.y)/3.0 + 2
// 	            };
// 	            this.addLabel(node.rate, pos, {width: 100, height: 70}, 'funnel_rate_label', 'funnel_rate_'+node.id);
// 						}
//         }
//     },
//     addLabel: function(text, position, size, classname, id){
//         var label = new Element('div', {
//             'class': classname,
// 						'id': id
//         });
// 		  label.setStyle({
// 	  		top: position.y+this.element.positionedOffset().top+'px',
// 				left: position.x+this.element.positionedOffset().left+'px',
// 				width: size.width+'px',
// 				height: size.height+'px',
// 				position: 'absolute',
// 				textAlign: 'center',
// 				fontSize: '13px',
// 				marginTop: '5px'
// 		  });
//         label.update(text);
//         this.labels.push(label);
//         this.element.insert(label);
//     },
//     updateLabels: function(){
//         for (var i = 0; i < this.funnel_nodes.length - 1; i++) {
// 					this.labels[1 + i*2].update(this.funnel_nodes[i].rate);
//         }
//     }
// };
