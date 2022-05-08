defmodule SampleWeb.AdminUserConfirmationControllerTest do
  use SampleWeb.ConnCase, async: true

  alias Sample.Admin
  alias Sample.Repo
  import Sample.AdminFixtures

  setup do
    %{admin_user: admin_user_fixture()}
  end

  describe "GET /admin_users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.admin_user_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /admin_users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, admin_user: admin_user} do
      conn =
        post(conn, Routes.admin_user_confirmation_path(conn, :create), %{
          "admin_user" => %{"email" => admin_user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Admin.AdminUserToken, admin_user_id: admin_user.id).context == "confirm"
    end

    test "does not send confirmation token if Admin user is confirmed", %{conn: conn, admin_user: admin_user} do
      Repo.update!(Admin.AdminUser.confirm_changeset(admin_user))

      conn =
        post(conn, Routes.admin_user_confirmation_path(conn, :create), %{
          "admin_user" => %{"email" => admin_user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Admin.AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.admin_user_confirmation_path(conn, :create), %{
          "admin_user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Admin.AdminUserToken) == []
    end
  end

  describe "GET /admin_users/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.admin_user_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.admin_user_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /admin_users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, admin_user: admin_user} do
      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_admin_user_confirmation_instructions(admin_user, url)
        end)

      conn = post(conn, Routes.admin_user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Admin user confirmed successfully"
      assert Admin.get_admin_user!(admin_user.id).confirmed_at
      refute get_session(conn, :admin_user_token)
      assert Repo.all(Admin.AdminUserToken) == []

      # When not logged in
      conn = post(conn, Routes.admin_user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Admin user confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_admin_user(admin_user)
        |> post(Routes.admin_user_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, admin_user: admin_user} do
      conn = post(conn, Routes.admin_user_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Admin user confirmation link is invalid or it has expired"
      refute Admin.get_admin_user!(admin_user.id).confirmed_at
    end
  end
end
