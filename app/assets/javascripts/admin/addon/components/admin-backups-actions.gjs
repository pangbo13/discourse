import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";

export default class AdminBackupsActions extends Component {
  @service currentUser;
  @service site;
  @service dialog;

  @action
  toggleReadOnlyMode() {
    if (!this.site.isReadOnly) {
      this.dialog.yesNoConfirm({
        message: I18n.t("admin.backups.read_only.enable.confirm"),
        didConfirm: () => {
          this.currentUser.set("hideReadOnlyAlert", true);
          this.#toggleReadOnlyMode(true);
        },
      });
    } else {
      this.#toggleReadOnlyMode(false);
    }
  }

  get rollbackDisabled() {
    return !this.rollbackEnabled;
  }

  get rollbackEnabled() {
    return (
      this.args.backups.canRollback &&
      this.args.backups.restoreEnabled &&
      !this.args.backups.isOperationRunning
    );
  }

  async #toggleReadOnlyMode(enable) {
    try {
      await ajax("/admin/backups/readonly", {
        type: "PUT",
        data: { enable },
      });
      this.site.set("isReadOnly", enable);
    } catch (err) {
      popupAjaxError(err);
    }
  }

  <template>
    {{#if @backups.isOperationRunning}}
      <@actions.Danger
        @action={{routeAction "cancelOperation"}}
        @title="admin.backups.operations.cancel.title"
        @label="admin.backups.operations.cancel.label"
        @icon="times"
        class="admin-backups__cancel"
      />
    {{else}}
      <@actions.Primary
        @action={{routeAction "showStartBackupModal"}}
        @title="admin.backups.operations.backup.title"
        @label="admin.backups.operations.backup.label"
        @icon="rocket"
        class="admin-backups__start"
      />
    {{/if}}

    {{#if @backups.canRollback}}
      <@actions.Default
        @action={{routeAction "rollback"}}
        @label="admin.backups.operations.rollback.label"
        @title="admin.backups.operations.rollback.title"
        @icon="ambulance"
        @disabled={{this.rollbackDisabled}}
        class="admin-backups__rollback"
      />
    {{/if}}

    <@actions.Default
      @icon={{if this.site.isReadOnly "far-eye-slash" "far-eye"}}
      @action={{this.toggleReadOnlyMode}}
      @disabled={{@backups.isOperationRunning}}
      @title={{if
        this.site.isReadOnly
        "admin.backups.read_only.disable.title"
        "admin.backups.read_only.enable.title"
      }}
      @label={{if
        this.site.isReadOnly
        "admin.backups.read_only.disable.label"
        "admin.backups.read_only.enable.label"
      }}
      class="admin-backups__toggle-read-only"
    />
  </template>
}
