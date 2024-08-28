#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "messages.g.h"

#include "player.cc"

#include <iostream>
#include <string>
#include <vector>

struct _MyApplication {
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;

  AudioPlayer *player;

  PigeonMelodinkMelodinkHostPlayerApiInfo *flutter_api;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

std::vector<const char *> fl_value_to_vector_string(FlValue *fl_value) {
  std::vector<const char *> result;

  if (fl_value_get_type(fl_value) == FL_VALUE_TYPE_LIST) {
    gsize list_length = fl_value_get_length(fl_value);

    for (gsize i = 0; i < list_length; i++) {
      FlValue *item = fl_value_get_list_value(fl_value, i);

      if (fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
        const gchar *str = fl_value_get_string(item);
        result.push_back(str);
      }
    }
  }

  return result;
}

static PigeonMelodinkMelodinkHostPlayerApiPlayResponse *
handle_play(gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->play();

  return pigeon_melodink_melodink_host_player_api_play_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiPauseResponse *
handle_pause(gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->pause();

  return pigeon_melodink_melodink_host_player_api_pause_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiSeekResponse *
handle_seek(int64_t position_ms, gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->seek(position_ms);

  return pigeon_melodink_melodink_host_player_api_seek_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiSkipToPreviousResponse *
handle_skip_to_previous(gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->prev();

  return pigeon_melodink_melodink_host_player_api_skip_to_previous_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiSkipToNextResponse *
handle_skip_to_next(gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->next();

  return pigeon_melodink_melodink_host_player_api_skip_to_next_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiSetAudiosResponse *
handle_set_audios(FlValue *previous_urls, FlValue *next_urls,
                  gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->set_audios(fl_value_to_vector_string(previous_urls),
                          fl_value_to_vector_string(next_urls));

  return pigeon_melodink_melodink_host_player_api_set_audios_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiSetLoopModeResponse *
handle_set_loop_mode(PigeonMelodinkMelodinkHostPlayerLoopMode loop,
                     gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->set_loop_mode(loop);

  return pigeon_melodink_melodink_host_player_api_set_loop_mode_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiFetchStatusResponse *
handle_fetch_status(gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  return pigeon_melodink_melodink_host_player_api_fetch_status_response_new(
      pigeon_melodink_player_status_new(
          app->player->get_current_playing(),
          app->player->get_current_track_pos(),
          app->player->get_current_position(),
          app->player->get_current_buffered_position(),
          app->player->get_current_player_state(),
          app->player->get_current_loop_mode()));
}

static PigeonMelodinkMelodinkHostPlayerApiSetAuthTokenResponse *
handle_set_auth_token(const gchar *auth_token, gpointer user_data) {
  MyApplication *app = MY_APPLICATION(user_data);

  app->player->set_auth_token(auth_token);

  return pigeon_melodink_melodink_host_player_api_set_auth_token_response_new();
}

static PigeonMelodinkMelodinkHostPlayerApiVTable
    melodink_host_player_api_vtable = {
        .play = handle_play,
        .pause = handle_pause,
        .seek = handle_seek,
        .skip_to_next = handle_skip_to_next,
        .skip_to_previous = handle_skip_to_previous,
        .set_audios = handle_set_audios,
        .set_loop_mode = handle_set_loop_mode,
        .fetch_status = handle_fetch_status,
        .set_auth_token = handle_set_auth_token,
};

// Implements GApplication::activate.
static void my_application_activate(GApplication *application) {
  MyApplication *self = MY_APPLICATION(application);
  GtkWindow *window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen *screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar *wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar *header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "melodink_client");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "melodink_client");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView *view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  FlBinaryMessenger *messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  pigeon_melodink_melodink_host_player_api_set_method_handlers(
      messenger, nullptr, &melodink_host_player_api_vtable, self, nullptr);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));

  self->flutter_api =
      pigeon_melodink_melodink_host_player_api_info_new(messenger, nullptr);

  self->player = new AudioPlayer(self->flutter_api);
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication *application,
                                                  gchar ***arguments,
                                                  int *exit_status) {
  MyApplication *self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication *application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication *application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject *object) {
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  delete self->player;
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {}

MyApplication *my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
