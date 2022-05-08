defmodule SampleWeb.AdminUserResetPasswordController do
  use SampleWeb, :controller

  alias Sample.Admin

  plug :get_admin_user_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"admin_user" => %{"email" => email}}) do
    if admin_user = Admin.get_admin_user_by_email(email) do
      Admin.deliver_admin_user_reset_password_instructions(
        admin_user,
        &Routes.admin_user_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Admin.change_admin_user_password(conn.assigns.admin_user))
  end

  # Do not log in the admin_user after reset password to avoid a
  # leaked token giving the admin_user access to the account.
  def update(conn, %{"admin_user" => admin_user_params}) do
    case Admin.reset_admin_user_password(conn.assigns.admin_user, admin_user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.admin_user_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_admin_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if admin_user = Admin.get_admin_user_by_reset_password_token(token) do
      conn |> assign(:admin_user, admin_user) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
