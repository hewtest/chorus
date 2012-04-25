describe("chorus.views.WorkspaceListSidebar", function() {
    beforeEach(function() {
        this.workspace = newFixtures.workspace();
        this.view = new chorus.views.WorkspaceListSidebar();

        chorus.PageEvents.broadcast("workspace:selected", this.workspace);
    });

    it("displays the workspace name", function() {
        expect(this.view.$(".name")).toContainText(this.workspace.get("name"));
    })

    context("the workspace has an image", function() {
        beforeEach(function() {
            spyOn(this.view.model, 'hasImage').andReturn(true);
            this.spyImg = spyOn(this.view.model, 'imageUrl').andReturn("/userimage/party.gif")
            this.view.render();
        });

        it("renders the workspace image", function() {
            expect(this.view.$("img.workspace_image").attr("src")).toContain('/userimage/party.gif');
        });
    });

    context("the workspace does not have an image", function() {
        beforeEach(function() {
            spyOn(this.view.model, 'hasImage').andReturn(false);
            spyOn(this.view.model, 'imageUrl').andReturn("/party.gif")
            this.view.render();
        });

        it("does not render the workspace image", function() {
            expect(this.view.$("img.workspace_image")).not.toExist();
        });
    });

    it("has the workspace member list", function() {
        expect(this.view.$(".workspace_member_list")[0]).toBe(this.view.workspaceMemberList.el);
    })

    describe("when the activity fetch completes", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace.activities());
        });

        it("renders an activity list inside the tabbed area", function() {
            expect(this.view.tabs.activity).toBeA(chorus.views.ActivityList);
            expect(this.view.tabs.activity.el).toBe(this.view.$(".tabbed_area .activity_list")[0]);
        });
    });

    it("has actions to add a note and to add an insight", function() {
        expect(this.view.$(".actions a[data-dialog=NotesNew]")).toContainTranslation("actions.add_note");
        expect(this.view.$(".actions a[data-dialog=InsightsNew]")).toContainTranslation("actions.add_insight");
    });
})
