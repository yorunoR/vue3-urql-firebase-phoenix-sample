defmodule SampleWeb.AdminUserConfirmationController do
  use SampleWeb, :controller

  alias Sample.Admin

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"admin_user" => %{"email" => email}}) do
    if admin_user = Admin.get_admin_user_by_email(email) do
      Admin.deliver_admin_user_confirmation_instructions(
        admin_user,
        &Routes.admin_user_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the admin_user after confirmation to avoid a
  # leaked token giving the admin_user access to the account.
  def update(conn, %{"token" => token}) do
    case Admin.confirm_admin_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Admin user confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current admin_user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the admin_user themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_admin_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Admin user confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
