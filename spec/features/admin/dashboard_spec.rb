require 'rails_helper'

RSpec.feature 'Verify Dashboard', type: :feature do
    let!(:owner) { create(:admin) }
    let!(:ihmi) { create(:organization, name: "IHMI") }
    let!(:path) { create(:organization, name: "PATH") }

    login_page = LoginPage.new
    dashboard = DashboardPage.new
    home_page = HomePage.new

    it 'Verify organization is displayed in dashboard' do
      visit root_path
      login_page.do_login(owner.email, owner.password)
      #asssertion
      expect(dashboard.get_organization_count).to eq(2)
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end

    it 'Verify organisation name/count get updated in dashboard when new org is added via manage section' do

      visit root_path
      login_page.do_login(owner.email, owner.password)
      #total number of organizaiton present in dashborad
      organization_count = dashboard.get_organization_count

      home_page.select_manage_option("Organizations")
      organization = OrganizationsPage.new
      organization.create_new_organization("test", "testDescription")

      #assertion at organization screen
      expect(page).to have_content('Organization was successfully created.')
      organization.is_organization_name_present("test")

      home_page.select_main_menu_tab("Dashboard")
      #assertion at dashboard screen
      expect(page).to have_content("test")
      expect(dashboard.get_organization_count).to eq(organization_count + 1)
    end

    it 'SignIn as Owner and verify approval request in dashboard' do
      user = build(:user)
      user.sync_approval_status = User.sync_approval_statuses[:requested]
      user.save

      visit root_path
      login_page.do_login(owner.email, owner.password)

      expect(page).to have_content("Allow access")
      expect(page).to have_selector("i.fa-times")
      #check for user info
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(user.phone_number)
    end
  end
