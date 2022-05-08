defmodule SampleWeb.AdminUserSettingsController do
  use SampleWeb, :controller

  alias Sample.Admin
  alias SampleWeb.AdminUserAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "admin_user" => admin_user_params} = params
    admin_user = conn.assigns.current_admin_user

    case Admin.apply_admin_user_email(admin_user, password, admin_user_params) do
      {:ok, applied_admin_user} ->
        Admin.deliver_update_email_instructions(
          applied_admin_user,
          admin_user.email,
          &Routes.admin_user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.admin_user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "admin_user" => admin_user_params} = params
    admin_user = conn.assigns.current_admin_user

    case Admin.update_admin_user_password(admin_user, password, admin_user_params) do
      {:ok, admin_user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:admin_user_return_to, Routes.admin_user_settings_path(conn, :edit))
        |> AdminUserAuth.log_in_admin_user(admin_user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Admin.update_admin_user_email(conn.assigns.current_admin_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.admin_user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.admin_user_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    admin_user = conn.assigns.current_admin_user

    conn
    |> assign(:email_changeset, Admin.change_admin_user_email(admin_user))
    |> assign(:password_changeset, Admin.change_admin_user_password(admin_user))
  end
end
