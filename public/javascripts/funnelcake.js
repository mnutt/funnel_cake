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
FunnelCakeWidget.draw = function() {
	FunnelCakeWidget.widgets.each(function(widget){
		widget.draw();
	});
}
FunnelCakeWidget.update = function(options) {
	FunnelCakeWidget.widgets.each(function(widget){
		widget.update(options);
	});
}


//
// Widget for drawing a conversion funnel, with stats for
// conversion rate between startState and endState
//
var ConversionFunnel = Class.create(FunnelCakeWidget, {

	// Supply the element div that will hold the funnel display
  initialize: function($super, elem, options) {
		options = $H({
			topLabel: true,
			bottomLabel: true,
			startCount: false,
			endCount: false,
			rate: true,
			previousRate: true,
			dataUrl: '/analytics/conversions/'
		}).merge(options).toObject();
		if (!options.startState) { console.error("ConversionFunnel missing required 'startState'"); }
		if (!options.endState) { console.error("ConversionFunnel missing required 'endState'"); }

		$super(elem, options);
		this.build();
  },

	build: function() {
		// Create funnel parts
		this.topLabel = new Element('div', {'class': this.classesWithHidden('label top', this.options.topLabel)}).update(this.options.startState);
		this.bottomLabel = new Element('div', {'class': this.classesWithHidden('label bottom', this.options.bottomLabel)}).update(this.options.endState);
		this.startCount = new Element('span', {'class': this.classesWithHidden('count start', this.options.startCount)});
		this.endCount = new Element('span', {'class': this.classesWithHidden('count end', this.options.endCount)});
		this.rate = new Element('span', {'class': this.classesWithHidden('rate', this.options.rate)});
		this.previousRate = new Element('span', {'class': this.classesWithHidden('rate previous', this.options.previousRate)});
		this.spinner = new Element('img', {'class': 'spinner', 'style': 'display: none;', 'src': '/images/ajax-loader.gif'});

		// Create stats & funnel container
		this.statsContainer = new Element('div', {'class': 'stats_container'});
		this.statsContainer.insert({bottom: this.startCount});
		this.statsContainer.insert({bottom: '<br />'});
		this.statsContainer.insert({bottom: this.rate});
		this.statsContainer.insert({bottom: '<br />'});
		this.statsContainer.insert({bottom: this.previousRate});
		this.statsContainer.insert({bottom: '<br />'});
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
			y: (this.funnelContainer.getHeight())/5
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
			authenticity_token: FunnelCakeWidget.authenticity_token,
			time_period: opts.time_period,
			show_previous_period: this.previousRate.visible(),
			format: 'json'
		}).merge(opts);

		var thiz = this;
		new Ajax.Request(this.options.dataUrl+this.options.startState+'-'+this.options.endState,
			{
				format: 'json',
				asynchronous: true,
				method: 'get',
				parameters: params,
				onSuccess: function(transport) {
					var data = transport.responseJSON;
					thiz.startCount.update(data.stats.start_count);
					thiz.endCount.update(data.stats.end_count);
					thiz.rate.update(Math.round(data.stats.rate*100)+'%');
					thiz.previousRate.update('(' + Math.round(data.previous_stats.rate*100) + '%)');
					thiz.spinner.fade({duration: 0.5});
				}
			}
		);
	}


});



//
// Widget for drawing a data graph
//
var ConversionGraph = Class.create(FunnelCakeWidget, {

	// Supply the element div that will hold the funnel display
  initialize: function($super, elem, options) {
		options = $H({
			dataUrl: '/analytics/conversions/ID/history',
			stat: 'number',
			yaxis_min: null,
			yaxis_max: null
		}).merge(options).toObject();
		if (!options.startState) { console.error("ConversionGraph missing required 'startState'"); }
		if (!options.endState) { console.error("ConversionGraph missing required 'endState'"); }
		if (!options.stat) { console.error("ConversionGraph missing required 'stat'"); }

		options.dataUrl = options.dataUrl.replace('ID', options.startState+'-'+options.endState);

		$super(elem, options);
		this.build();
  },

	build: function() {
		// Create parts
		this.graph = new Element('div', {'class': 'graph'});
		this.spinner = new Element('img', {'class': 'spinner', 'style': 'display: none;', 'src': '/images/ajax-loader.gif'});
		this.exports = new Element('p', {'class': 'export'});

		// Add everything to the wrapper element
		this.element.insert({bottom: this.graph});
		this.element.insert({bottom: this.spinner});
		this.element.insert({bottom: this.exports});
	},

  draw: function() {
  },

	update: function(opts) {
		var thiz = this;
		this.graph.fade({
			duration: 0.25,
			afterFinish: function(){
				thiz.spinner.appear({duration: 0.25});
				thiz.graph.update('');

				var params = $H({
					authenticity_token: FunnelCakeWidget.authenticity_token,
					time_period: opts.time_period,
					format: 'json'
				}).merge(opts);

				new Ajax.Request(thiz.options.dataUrl,
				{
					format: 'json',
					asynchronous: true,
					method: 'get',
					parameters: params,
					onSuccess: function(transport) {
						var flotrData = thiz.constructFlotrData(transport.responseJSON);
						Flotr.draw( thiz.graph, flotrData.data, flotrData.options);
						thiz.graph.appear({duration: 0.35, afterFinish: function() {
							thiz.spinner.fade({duration: 0.5});
						}});
						thiz.updateExports(params);
					}
				});
			}
		});
	},

	// Update the export links
	updateExports: function(params) {
		params.set('format', 'csv');
		this.exports.update(new Element('a', {'href': this.options.dataUrl+'.csv?'+params.toQueryString()}).update('csv'));
	},

	constructFlotrData: function(rawdata) {
		var thiz = this;
		var sortedData = $H(rawdata).values().sortBy(function(e){return e.index});
		return {
			data: [{
				  data: sortedData.collect(function(e){return [e.index, e[thiz.options.stat]]}),
			    lines: {show: true, fill: true},
			    points: {show: true}
			}],
			options: {
	  	  xaxis: {
					ticks: sortedData.collect(function(e){return [e.index, e.date]}),		// => format: either [1, 3] or [[1, 'a'], 3]
					noTicks: 5,		// => number of ticks for automagically generated ticks
					tickFormatter: function(n){ return n; },
					tickDecimals: 0,	// => no. of decimals, null means auto
					min: null,		// => min. value to show, null means set automatically
					max: null,		// => max. value to show, null means set automatically
					autoscaleMargin: 0	// => margin in % to add if auto-setting min/max
				},
	  		yaxis: {
					ticks: null,		// => format: either [1, 3] or [[1, 'a'], 3]
					noTicks: 5,		// => number of ticks for automagically generated ticks
					tickFormatter: function(n){ return n; },
					tickDecimals: 0,	// => no. of decimals, null means auto
					min: this.options.yaxis_min,		// => min. value to show, null means set automatically
					max: this.options.yaxis_max,		// => max. value to show, null means set automatically
					autoscaleMargin: 0	// => margin in % to add if auto-setting min/max
			  }
			}
		};
	}

});



//
// Widget for drawing a table of data, for a specific state statistic
//
var DataTable = Class.create(FunnelCakeWidget, {

	// Supply the element div that will hold the funnel display
  initialize: function($super, elem, options) {
		options = $H({
			dataUrl: '/analytics/states/ID',
			category: 'date',
			stats: ['number']
		}).merge(options).toObject();
		if (!options.state) { console.error("ConversionGraph missing required 'state'"); }
		if (!options.category) { console.error("ConversionGraph missing required 'category'"); }
		if (!options.stats) { console.error("ConversionGraph missing required 'stats'"); }

		options.dataUrl = options.dataUrl.replace('ID', options.state);

		$super(elem, options);
		this.build();
  },

	build: function() {
		var thiz = this;

		// Create parts
		this.table = new Element('table', {'class': ''});
		this.spinner = new Element('img', {'class': 'spinner', 'style': 'display: none;', 'src': '/images/ajax-loader.gif'});

		// create exports
		this.exports = new Element('p', {'class': 'export'});

		// Add the header row
		this.header_row = new Element('tr', {'class': 'header'});
		this.category_header = new Element('th', {'class': 'category'}).update(this.options.category);
		this.header_row.insert({bottom: this.category_header});
		this.options.stats.each(function(stat){
			var data_header = new Element('th', {'class': stat}).update(stat);
			thiz.header_row.insert({bottom: data_header});
		});
		this.table.insert({bottom: this.header_row});

		// Add everything to the wrapper element
		this.element.insert({bottom: this.spinner});
		this.element.insert({bottom: this.table});
		this.element.insert({bottom: this.exports});
	},

  draw: function() {
  },

	update: function(opts) {
		var thiz = this;
		this.spinner.appear({ duration: 0.25 });
		this.table.select('tr.data').each(function(row) { row.remove(); });

		var params = $H({
			authenticity_token: FunnelCakeWidget.authenticity_token,
			time_period: opts.time_period,
			format: 'json'
		}).merge(opts);

		new Ajax.Request(thiz.options.dataUrl,
		{
			format: 'json',
			asynchronous: true,
			method: 'get',
			parameters: params,
			onSuccess: function(transport) {
				thiz.insertTableData(transport.responseJSON);
				thiz.spinner.fade({duration: 0.5});
				thiz.updateExports(params);
			}
		});
	},

	// Update the export links
	updateExports: function(params) {
		params.set('format', 'csv');
		this.exports.update(new Element('a', {'href': this.options.dataUrl+'.csv?'+params.toQueryString()}).update('csv'));
	},

	insertTableData: function(rawdata) {
		var thiz = this;
		var sortedData = $H(rawdata).values().sortBy(function(e){return e.index});
		sortedData.each(function(elem) {
			var row = new Element('tr', {'class': 'data'});
			var category = new Element('td').update(elem[thiz.options.category]);
			row.insert({bottom: category});
			thiz.options.stats.each(function(stat){
				var stat_td = new Element('td').update(elem[stat]);
				row.insert({bottom: stat_td});
			});
			thiz.table.insert({bottom: row});
		});
	}

});
