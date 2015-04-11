chorus.pages.SignupPage = chorus.pages.Bare.extend({
    setup:function () {
        this.mainContent = new chorus.views.Signup({model:chorus.session, el:this.el});
    },

    render:function () {
        this.mainContent.render();
        return this;
    }
});
