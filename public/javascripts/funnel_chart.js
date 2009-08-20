/*
 * FunnelChart class
 * - for drawing a funnel-style chart for conversion visualization
 */
function FunnelChart(_selector, _settings) {
	this.selector = _selector;
	this.settings = _settings;
};
FunnelChart.prototype = {
	draw: function(){
		var me = this;
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
			var width = (me.settings && me.settings.width) ? me.settings.width : element.getWidth();
			var padding = (me.settings && me.settings.padding) ? me.settings.padding : 0;

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

				if (me.settings.clickHandler) {
					label.observe('click', me.settings.clickHandler);
				}
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

	refreshData: function(opts) {
		if (!opts) opts = {};
		var me = this;
		$$(this.selector).each(function(e){
			var states = e.id.replace(/funnel_stage_/,'');
			var top_state = states.split(/-/)[0];
			var bottom_state = states.split(/-/)[1];
			e.down('.spinner').appear({duration: 0.25});

			var params = $H({
				authenticity_token: me.settings.authenticity_token,
				time_period: opts.time_period
			}).merge(opts);

			new Ajax.Request('/analytics/stages/'+top_state+'-'+bottom_state+'/stats',
				{
					asynchronous:true,
					evalScripts:true,
					method:'get',
					parameters: params
				}
			);
		});
	}

};

