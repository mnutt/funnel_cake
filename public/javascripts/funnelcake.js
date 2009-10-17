// Base class for FunnelCake widgets
var FunnelCakeWidget = Class.create({

	// Supply the element div that will hold the funnel display
  initialize: function(elem, opts) {
    this.element = elem;
		this.options = opts;

		// Add this widget to the list of widgets
		FunnelCakeWidget.addWidget(this);
  },

  update: function(options) {
	},

	classesWithHidden: function(classes, visible) {
		return classes + (visible ? '' : ' hidden');
	}

});

// Class-level list of FunnelCake widgets
FunnelCakeWidget.widgets = [];
FunnelCakeWidget.clearWidgets = function() {
	FunnelCakeWidget.widgets = [];
}
FunnelCakeWidget.addWidget = function(widget) {
	if (!FunnelCakeWidget.widgets) { FunnelCakeWidget.clearWidgets(); }
	FunnelCakeWidget.widgets.push(widget);
}


//
// Widget for drawing a conversion funnel, with stats for
// conversion rate between startState and endState
//
var ConversionFunnel = Class.create(FunnelCakeWidget, {

	// Supply the element div that will hold the funnel display
  initialize: function($super, elem, options) {
		options = $H(options).merge({
			topLabel: true,
			bottomLabel: true,
			startCount: false,
			endCount: false,
			rate: true,
			previousRate: true,
			dataUrl: '/analytics/conversions/'
		});
		if (!options.startState) { console.error("ConversionFunnel missing required 'startState'"); }
		if (!options.endState) { console.error("ConversionFunnel missing required 'endState'"); }

		$super(elem, options);
  },

	build: function() {
		// Create funnel parts
		this.topLabel = new Element('div', {'class': this.classesWithHidden('label top', this.options.topLabel)});
		this.bottomLabel = new Element('div', {'class': this.classesWithHidden('label bottom', this.options.bottomLabel)});
		this.startCount = new Element('div', {'class': this.classesWithHidden('count start', this.options.startCount)});
		this.endCount = new Element('div', {'class': this.classesWithHidden('count end', this.options.endCount)});
		this.rate = new Element('div', {'class': this.classesWithHidden('rate', this.options.rate)});
		this.previousRate = new Element('div', {'class': this.classesWithHidden('rate previous', this.options.previousRate)});
		this.spinner = new Element('div', {'class': 'spinner', 'style': 'display: none;'});

		// Create stats & funnel container
		this.statsContainer = new Element('div', {'class': 'stats_container'});
		this.statsContainer.insert({bottom: this.startCount});
		this.statsContainer.insert({bottom: this.rate});
		this.statsContainer.insert({bottom: this.previousRate});
		this.statsContainer.insert({bottom: this.endCount});
		this.funnelContainer = new Element('div', {'class': 'funnel_container'});
		this.funnelContainer.insert({bottom: this.statsContainer});

		// Add everything to the wrapper element
		this.element.insert({bottom: this.topLabel});
		this.element.insert({bottom: this.funnelContainer});
		this.element.insert({bottom: this.bottomLabel});
		this.element.insert({bottom: this.spinner});
	},

  draw: function() {

		// Initialize Canvas
		var canvas = $(this.funnelContainer).getElementsByTagName("canvas")[0];
		if (!canvas) {
			canvas = new Element('canvas', {
				'width': this.funnelContainer.getWidth(),
				'height': this.funnelContainer.getHeight(),
				'id': this.funnelContainer.id + '_canvas'
			});
		  canvas.setStyle({
				border: '0',
				padding: '0'
		  });
			this.funnelContainer.insert(canvas, {position: 'top'});
		}
	  var ctx = canvas.getContext("2d");

		// Init values from settings
		var width = this.options.width ? this.options.width : this.funnelContainer.getWidth();
		var padding = this.options.padding ? this.options.padding : 0;

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
		ctx.lineTo(width / 2.0 + 10, this.funnelContainer.getHeight());
		ctx.lineTo(width / 2.0 - 10, this.funnelContainer.getHeight());
		ctx.lineTo(padding, 0);
		ctx.fill();
		ctx.stroke();

		// Position the statsContainer
		var labelpos = {
			x: 0,
			y: (this.funnelContainer.getHeight())/3.5
		};
		this.statsContainer.setStyle({
			top: labelpos.y + this.funnelContainer.positionedOffset().top + 'px',
			left: labelpos.x + this.funnelContainer.positionedOffset().left + 'px',
			width: width + 'px',
			position: 'absolute'
		});

		// Set the clickHandler, if it exists
		if (this.options.clickHandler) {
			this.statsContainer.observe('click', this.options.clickHandler);
		}

		// Position the spinner
		var labelpos = {
			x: this.funnelContainer.getWidth()/2 - 10,
			y: (this.funnelContainer.getHeight() - padding)/5
		};
		this.spinner.setStyle({
			top: labelpos.y + this.funnelContainer.positionedOffset().top + 'px',
			left: labelpos.x + this.funnelContainer.positionedOffset().left + 'px',
			position: 'absolute'
		});

  },

	update: function(opts) {
		this.spinner.appear({duration: 0.25});

		var params = $H({
			authenticity_token: me.settings.authenticity_token,
			time_period: opts.time_period,
			show_previous_period: this.previousRate.visible()
		}).merge(opts);

		new Ajax.Request(this.options.dataUrl+this.options.startState+'-'+this.options.endState,
			{
				format: 'json'
				asynchronous: true,
				evalScripts: true,
				method: 'post',
				parameters: params
			}
		);
	}


});
