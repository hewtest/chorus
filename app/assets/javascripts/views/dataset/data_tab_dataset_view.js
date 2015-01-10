chorus.views.DataTabDataset = chorus.views.Base.extend({
    constructorName: "DataTabDatasetView",
    templateName: "data_tab_dataset",
    tagName: "li",

    events: {
        "click .name a": "nameClicked",
        "click .toggle_visibility": "toggleVisibility"
    },

    postRender: function() {
        this.$el.data("fullname", this.model.toText());
        this.$el.data("name", this.model.name());
    },

    setup: function() {
        this.columnsVisible = false;
    },

    teardown: function() {
        this.$el.qtip("destroy");
        this._super("teardown", arguments);
    },

    additionalContext: function() {
        return {
            name: this.model.name(),
            iconUrl: this.model.iconUrl({size: "small"})
        };
    },

    nameClicked: function(e) {
        e.preventDefault();
        this.toggleVisibility();
    },

    toggleVisibility: function() {
        if(!this.columnsVisible) {
            this.columnList = this.buildColumnList();
            this.registerSubView(this.columnList);
            this.columnList.render();
        } else {
            this.columnList.teardown(true);
        }

        this.columnsVisible = !this.columnsVisible;
        this.updateArrowIcon();
    },

    updateArrowIcon: function() {
        var imageUrl = this.columnsVisible ? '/images/close.gif' : '/images/expand.gif';
        this.$('img:eq(0)').attr('src', imageUrl);
    },

    buildColumnList: function() {
        return new chorus.views.DataTabDatasetColumnList({
            el: this.$(".column_list"),
            dataset: this.model
        });
    }
});