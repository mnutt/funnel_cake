// Base class for FunnelCake widgets
var FunnelCakeWidget = Class.create({

	// Supply the element div that will hold the funnel display
  initialize: function(elem, opts) {
    this.element = elem;
		this.options = opts;

		// Add this widget to the list of widgets
		FunnelCakeWidget.addWidget(this);
  },

  update: function(options) {},

  draw: function() {},

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
			startCount: true,
			endCount: true,
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
		this.options.topLabelText = (this.options.topLabel==true) ? this.options.startState : this.options.topLabel;
		this.options.bottomLabelText = (this.options.bottomLabel==true) ? this.options.endState : this.options.bottomLabel;
		this.topLabel = new Element('div', {'class': this.classesWithHidden('label top', this.options.topLabel)}).update(this.options.topLabelText);
		this.bottomLabel = new Element('div', {'class': this.classesWithHidden('label bottom', this.options.bottomLabel)}).update(this.options.bottomLabelText);
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
					thiz.startCount.update(data.stats.start);
					thiz.endCount.update(data.stats.end);
					thiz.rate.update(Math.round(data.stats.rate*100)+'%');
					thiz.previousRate.update('' + Math.round(data.previous_stats.rate*100) + '%');
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
			yaxis_max: null,
			yaxis_is_percentage: null,
		}).merge(options).toObject();
		if (!options.startState) { console.error("ConversionGraph missing required 'startState'"); }
		if (!options.endState) { console.error("ConversionGraph missing required 'endState'"); }
		if (!options.stat) { console.error("ConversionGraph missing required 'stat'"); }

    options.yaxis_is_percentage = (options.stat=='rate') ? true : options.yaxis_is_percentage;
		options.dataUrl = options.dataUrl.replace('ID', options.startState+'-'+options.endState);
		options.style = options.style ? options.style : '';

		$super(elem, options);
		this.build();
  },

	build: function() {
		// Create parts
		this.graph = new Element('div', {'class': 'graph', 'style': this.options.style});
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

  // Data Format:
  // {
  //   a: {
  //      "0": {"date":"03/26","number":26,"rate":1.51869158878505,"index":0},
  //      "1":{"date":"12/18","number":28,"rate":1.30963517305893,"index":1},
  //   },
  //   b: {
  //      "0": {"date":"03/26","number":26,"rate":1.51869158878505,"index":0},
  //      "1":{"date":"12/18","number":28,"rate":1.30963517305893,"index":1},
  //   }
  // }
	constructFlotrData: function(rawdata) {
		var thiz = this;
		var dataHash = $H(rawdata);

		var sortedData = dataHash.values().collect(function(series){
		  return $H(series).values().sortBy(function(e){return e.index});
		});
    var flotrData = sortedData.collect(function(series){
      return {
        data: series.collect(function(e){return [e.index, e[thiz.options.stat]]}),
		    lines: {show: true, fill: true},
		    points: {show: true}
	    };
    });

    var ymin = sortedData.collect(function(series){
      return series.collect(function(e){return e[thiz.options.stat]}).min();
    }).min();
    var ymax = sortedData.collect(function(series){
      return series.collect(function(e){return e[thiz.options.stat]}).max();
    }).max();
		var yaxis_min = ymin;
		var yaxis_max = ymax;
	  var range = yaxis_max-yaxis_min;
		if (this.options.yaxis_is_percentage) {
  		yaxis_min = yaxis_min - range*1.5;
  		yaxis_max = yaxis_max + range*1.5;
      yaxis_min = $A([yaxis_min, 0.0]).max();
  		yaxis_max = $A([yaxis_max, 100.0]).min();
  		yaxis_min = (yaxis_min < 10.0) ? 0.0 : yaxis_min;
  		yaxis_max = (yaxis_max > 90.0) ? 100.0 : yaxis_max;
		} else {
  		yaxis_min = yaxis_min - range/2.0;
  		yaxis_max = yaxis_max + range/2.0;
      yaxis_min = $A([yaxis_min, 0.0]).max();
		}
		return {
			data: flotrData,
			options: {
	  	  xaxis: {
					ticks: sortedData[0].collect(function(e){return [e.index, e.date]}),		// => format: either [1, 3] or [[1, 'a'], 3]
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
					min: this.options.yaxis_min || yaxis_min,		// => min. value to show, null means set automatically
					max: this.options.yaxis_max || yaxis_max,		// => max. value to show, null means set automatically
					autoscaleMargin: 0	// => margin in % to add if auto-setting min/max
			  },
        mouse: {
          track: true,
          color: 'blue',
          sensibility: 3, // => distance to show point get's smaller
          trackDecimals: 2,
          trackFormatter: function(obj){ return obj.y; }
        }
			}
		};
	}

});


//
// Widget for drawing a data state diagram
//
var ConversionDiagram = Class.create(FunnelCakeWidget, {

	// Supply the element div that will hold the funnel display
  initialize: function($super, elem, options) {
		options = $H({
			dataUrl: '/analytics/dashboards/diagram',
			scale: 0.45,
			xdot: ''
		}).merge(options).toObject();
		if (!options.xdot) { console.error("ConversionDiagram missing required 'xdot'"); }

		options.style = options.style ? options.style : '';

		$super(elem, options);
		this.build();
  },

	build: function() {
		// Create parts
		this.diagram = new Element('div', {'class': 'diagram', 'style': this.options.style});
		this.spinner = new Element('img', {'class': 'spinner_bar', 'style': 'display: none; position: absolute;', 'src': '/images/ajax-loader-bar.gif'});
		this.label = new Element('p', {'class': 'label'});

		// Add everything to the wrapper element
		this.element.insert({bottom: this.diagram});
		this.element.insert({bottom: this.spinner});
		this.element.insert({bottom: this.label});
	},

  draw: function() {
		this.canviz = new Canviz(this.diagram);
		this.canviz.setImagePath('/images/');
		this.canviz.setScale(this.options.scale);
		this.canviz.parse(this.options.xdot);
  },

	update: function(opts) {
		var thiz = this;

		thiz.spinner.setStyle({
			left: thiz.diagram.positionedOffset().left + thiz.diagram.getWidth()/2.0 - thiz.spinner.getWidth()/2.0 + 'px',
			top: thiz.diagram.positionedOffset().top + thiz.diagram.getHeight()/3.0 - thiz.spinner.getHeight()/2.0 + 'px'
		});
		thiz.diagram.fade({duration: 0.5, from: 1.0, to: 0.5});
		thiz.spinner.appear({duration: 0.25});

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
				thiz.updateDiagramLabels(transport.responseJSON);
				thiz.spinner.fade({duration: 0.25});
				thiz.diagram.appear({duration: 0.5, from: 0.5, to: 1.0});
			}
		});
	},

	updateDiagramLabels: function(rawdata) {
		var thiz = this;
		var nodes = {};

		// First, iterate through the transitions, setting the edge labels and recording the node data
		$A(rawdata).each(function(transition){
			if (Object.isUndefined(nodes[transition.from])) { nodes[transition.from] = { count_in: 0, count_out: 0, primary: false }; }
			if (Object.isUndefined(nodes[transition.to])) { nodes[transition.to] = { count_in: 0, count_out: 0, primary: false }; }

			nodes[transition.from].count_out = [nodes[transition.from].count_out, transition.stats.start_count].max();
			nodes[transition.to].count_in += transition.stats.end_count;
			nodes[transition.to].primary = transition.to_primary;

			$(transition.from+'_to_'+transition.to+'_edge').update(transition.stats.end_count);
		});

		// Then, iterate through the node data, setting the node labels
		$H(nodes).each(function(pair){
		  var node_html = "<div class='entering'>"+pair.value.count_in+"&rarr;</div>"
		  node_html += "<div class='label'>"+pair.key+"</div>"
		  node_html += "<div class='exiting'>"+pair.value.count_out+"&rarr;</div>"
			$(pair.key+'_node').update(node_html)
			if (pair.value.primary) { $(pair.key+'_node').addClassName('primary'); }
		});
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
		var sortedData = $H($H(rawdata).values()[0]).values().sortBy(function(e){return e.index});
		sortedData.each(function(elem) {
			var row = new Element('tr', {'class': 'data'});

			var content = elem[thiz.options.category];
			if (thiz.options.statPreprocessor) {
				content = thiz.options.statPreprocessor(elem, thiz.options.category);
			}
			var category = new Element('td').update(content);

			row.insert({bottom: category});
			thiz.options.stats.each(function(stat){
				var content = elem[stat];
				if (thiz.options.statPreprocessor) {
					content = thiz.options.statPreprocessor(elem, stat);
				}
				var stat_td = new Element('td').update(content);
				row.insert({bottom: stat_td});
			});
			thiz.table.insert({bottom: row});
		});
	}

});
