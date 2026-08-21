import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import PluginOutlet from "discourse/components/plugin-outlet";
import SearchMenu from "discourse/components/search-menu";
import themeI18n from "discourse/helpers/theme-i18n";
import themeSetting from "discourse/helpers/theme-setting";
import { defaultHomepage } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";
import SearchIcon from "./search-icon";

export default class SearchBanner extends Component {
  @service router;
  @service siteSettings;
  @service currentUser;

  @action
  willDestroy() {
    super.willDestroy(...arguments);
    document.documentElement.classList.remove("display-search-banner");
  }

  get displayForRoute() {
    const showOn = settings.show_on;
    const currentRouteName = this.router.currentRouteName;

    if (showOn === "homepage") {
      return currentRouteName === `discovery.${defaultHomepage()}`;
    } else if (showOn === "top_menu") {
      return this.siteSettings.top_menu
        .split("|")
        .any((m) => `discovery.${m}` === currentRouteName);
    } else if (showOn === "discovery") {
      return currentRouteName.startsWith("discovery.");
    } else {
      // "all"
      return (
        currentRouteName !== "full-page-search" &&
        !currentRouteName.startsWith("admin.")
      );
    }
  }

  get displayForUser() {
    const showFor = settings.show_for;
    return (
      showFor === "everyone" ||
      (showFor === "logged_out" && !this.currentUser) ||
      (showFor === "logged_in" && this.currentUser)
    );
  }

  get buttonText() {
    const buttonText = i18n(themePrefix("search_banner.search_button_text"));
    // this is required for when the English (US) locale is empty
    // and the site locale is set to another language
    // otherwise the English (US) fallback key is rendered as the button text
    // https://meta.discourse.org/t/bug-with-search-banner-search-button-text-shown-in-search-banner-theme-component/273628
    if (buttonText.includes("theme_translations")) {
      return false;
    }

    return buttonText;
  }

  get headlineText() {
    const headlineText = i18n(themePrefix("search_banner.headline"));
    return headlineText;
  }

  get highlightText() {
    const highlightText = i18n(themePrefix("search_banner.highlight"));
    return highlightText;
  }

  get shouldDisplay() {
    return this.displayForRoute && this.displayForUser;
  }

  @action
  didInsert() {
    // Setting a class on <html> from a component is not great
    // but we need it for backwards compatibility
    document.documentElement.classList.add("display-search-banner");
  }

  <template>
    {{#if this.shouldDisplay}}
      <div
        class="{{concat (themeSetting 'plugin_outlet') '-outlet'}} search-banner"
      >
        <div
          class="custom-search-banner welcome-banner"
          {{didInsert this.didInsert}}
          {{willDestroy this.willDestroy}}
        >
          <div class="wrap custom-search-banner-wrap">
            <h1>{{this.headlineText}}
              <span class="highlight">{{this.highlightText}}</span></h1>
            <PluginOutlet @name="search-banner-below-headline" />
            <p>{{htmlSafe (themeI18n "search_banner.subhead")}}</p>
            <div class="search-menu">
              {{#unless this.buttonText}}
                <SearchIcon />
              {{/unless}}
              <SearchMenu />
              {{#if this.buttonText}}
                <SearchIcon
                  @buttonText={{this.buttonText}}
                  @buttonClass="has-search-button-text"
                />
              {{/if}}
            </div>
            <PluginOutlet @name="search-banner-below-input" />
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
