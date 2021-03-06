# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

module SupplejackApi
  describe Harvester::RecordsController, type: :controller do
    routes { SupplejackApi::Engine.routes }

    let(:record) { FactoryGirl.build(:record) }

    describe "POST create" do
      before(:each) do
        allow(Record).to receive(:find_or_initialize_by_identifier) { record }
      end

      context "preview is false" do
        it "finds or initializes a record by identifier" do
          expect(Record).to receive(:find_or_initialize_by_identifier).with("internal_identifier" => "1234") { record }
          post :create, record: {internal_identifier: "1234"}
          expect(assigns(:record)).to eq record
        end
      end

      context "preview is true" do
        it "finds or initializes a preview record by identifier" do
          expect(PreviewRecord).to receive(:find_or_initialize_by_identifier).with("internal_identifier" => "1234") { record }
          post :create, record: {internal_identifier: "1234"}, preview: true
          expect(assigns(:record)).to eq record
        end
      end

      context "record has a priority other then 0" do
        it "creates or updates the fragment" do
          rec = {
            "internal_identifier" => "1234",
            "title" => "Hi",
            "priority" => "10"
          }
          expect(record).to receive(:create_or_update_fragment).with(rec)
          post :create, record: rec
        end
      end

      it "sets the status based on the required fragments" do
        expect(record).to receive(:set_status).with(['ndha_rights'])
        post :create, record: {"internal_identifier" => "1234"}, required_fragments: ['ndha_rights']
      end

      it "saves the record" do
        expect(record).to receive(:save)
        post :create, record: {"internal_identifier" => "1234"}
      end

      it "unsets null fields" do
        expect(record).to receive(:unset_null_fields)
        post :create, record: {"internal_identifier" => "1234"}
      end

      it 'returns status success and record_id if no exception is raised' do
        allow(Record).to receive(:find_or_initialize_by_identifier) { record }

        post :create, record: { 'internal_identifier' => '1234' }

        data = JSON.parse(response.body)

        expect(data['status']).to eq 'success'
        expect(data['record_id']).to eq record.record_id
      end

      it 'returns status failed and backtrace metadata when an exception is raised' do
        allow(Record).to receive(:find_or_initialize_by_identifier) { record }
        allow(record).to receive(:save!).and_raise(StandardError.new('bang'))

        post :create, record: { 'internal_identifier' => '1234' }

        data = JSON.parse(response.body)

        expect(data['status']).to eq 'failed'
        expect(data['exception_class']).to eq 'StandardError'
        expect(data['message']).to eq 'bang'
        expect(data['raw_data']).to eq record.to_json
        expect(data['backtrace']).not_to be_empty
        expect(data['record_id']).to eq record.record_id
      end
    end

    describe "PUT delete" do
      it "should find the record by internal_identifier" do
        expect(Record).to receive(:where).with({internal_identifier: "abc123"}) { [record] }
        put :delete, id: "abc123"
        expect(assigns(:record)).to eq record
      end

      it "should update the records status attribute to deleted" do
        allow(Record).to receive(:where) { [record] }
        expect(record).to receive(:update_attribute).with(:status, "deleted")
        put :delete, id: "abc123"
      end

      it "handles a nil record" do
        allow(Record).to receive(:where) { [] }
        expect { put :delete, id: "abc123" }.to_not raise_exception
      end

      it 'returns status success if no exception is raised' do
        allow(Record).to receive(:where) { [record] }
        put :delete, id: 'abc123'

        data = JSON.parse(response.body)
        expect(data['status']).to eq 'success'
        expect(data['record_id']).to eq 'abc123'
      end

      it 'returns status failed and backtrace metadata when an exception is raised' do
        allow(Record).to receive(:where).and_raise(StandardError.new('bang'))
        put :delete, id: 'abc123'

        data = JSON.parse(response.body)
        expect(data['status']).to eq 'failed'
        expect(data['exception_class']).to eq 'StandardError'
        expect(data['message']).to eq 'bang'
        expect(data['backtrace']).not_to be_empty
        expect(data['record_id']).to eq 'abc123'
      end
    end

    describe "DELETE flush" do
      before do
        allow(Record).to receive(:flush_old_records)
        expect(FlushOldRecordsWorker).to receive(:perform_async).with('tapuhi', 'abc123')
      end

      it "calls flush_old_records" do
        delete :flush, source_id: 'tapuhi', job_id: 'abc123'
      end

      it "returns a 204" do
        delete :flush, source_id: 'tapuhi', job_id: 'abc123'

        expect(response.code).to eq '204'
      end
    end

    describe 'GET #show' do
      it 'should find the record by internal_identifier' do
        expect(Record).to receive(:where).with({ record_id: 'abc123' }) { [record] }
        get :show, id: 'abc123'
      end

      it 'should assign the record to @record' do
        allow(Record).to receive(:where) { [record] }
        get :show, id: 'abc123'
        expect(assigns(:record)).to eq record
      end

      it 'should handle a nil record' do
        allow(Record).to receive(:where) { [] }
        expect { get :show, id: 'abc123' }.to_not raise_exception
      end
    end

    describe "PUT update" do
      let(:record) { double(:record).as_null_object }

      before do
        allow(controller).to receive(:authenticate_user!) { true }
        allow(Record).to receive(:custom_find) { record }
      end

      it 'finds the record and asigns it' do
        expect(Record).to receive(:custom_find).with('123', nil, {status: :all}) { record }
        put :update, id: 123, record: { status: 'supressed' }, format: :json
        expect(assigns(:record)).to eq(record)
      end

      it "updates the status of the record" do
        expect(record).to receive(:update_attribute).with(:status, 'supressed')
        put :update, id: 123, record: { status: 'supressed' }, format: :json
      end
    end
  end
end
