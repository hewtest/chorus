chorus.dialogs.JobResultDetail = chorus.dialogs.Base.extend({
    constructorName: 'JobResultDetailDialog',
    templateName: "job_result_detail_dialog",
    additionalClass: "dialog_wide",

    makeModel: function () {
        if (this.model) {
            this.job = new chorus.models.Job(this.options.model.get("job"));
        } else {
            this.job = this.options.job;
            this.model = new chorus.models.JobResult({jobId: this.job.id, id: 'latest'});
            this.model.fetch();
        }
        
//         this.model.get("action")
    },

    setup: function () {
        this.title = t("job.result_details.title", {jobName: this.job.name()});

        this.render();
    },

    additionalContext: function () {
        //console.log ("additionalContext");
        //console.log ("1: "+ this.model.status); 
        //console.log ("2: "+ this.model.status() );
        //console.log ("3: "+ this.status ); undefined
        //console.log ("4: "+ this.status() );
        //console.log ("5: "+ status );
        //console.log ("6+: "+ this.model.get('status') );
        //console.log ("7: "+ this.get("status") );
        // console.log ("8: "+ this.job.get('status') );
         //console.log ("10: "+ this.model.jobTaskResults);
         //.get('status') );
         //console.log ("12: "+ this.job.jobTaskResults);
    
        
        return {
            statusDisplay: this.taskStatus(),
        };
    },
    
    // jobStatus: map the success or failure status to visuals
    taskStatus: function () {
        return ("smelly");
//         if (this.model.status === "success" ) {
//             console.log ("success");
//         }
//         else if (this.model.status === "failure" ) {
//             console.log ("failure");
//         }
    
    }
// t("job.result_details.status_success") = Successful
// t("job.result_details.status_failure") = Task failed

});