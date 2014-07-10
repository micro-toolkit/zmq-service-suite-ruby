require 'spec_helper'
require 'zss/router'

describe ZSS::Router do

  class Dummy

    def print(payload); end

    def print_with_headers(payload, header); end

  end

  subject { described_class.new }

  let(:context_object) { Dummy.new }

  describe('#ctor') do

  end

  describe('#add_route') do

    it('register route successfully') do
      subject.add(context_object, "print", :print)
    end

    it('register route successfully without handler') do
      subject.add(context_object, :print)
    end


    context('on error') do

      it('raises a Error on invalid context') do
        expect { subject.add(nil, :route) }.
          to raise_exception
      end

      it('raises a Error on invalid route') do
        expect { subject.add(context_object, nil) }.
          to raise_exception
      end

      it('raises a Error on invalid handler') do
        expect { subject.add(context_object, :route) }.
          to raise_exception
      end

    end

  end

  describe('#get_route') do

    before(:each) do
      subject.add(context_object, "print", :print)
      subject.add(context_object, "print_with_headers", :print_with_headers)
    end

    context('on error') do

      it('raises a ZSS::Error on invalid verb') do
        expect { subject.get("route") }.
          to raise_exception(ZSS::Error)
      end

    end

    context('on success') do

      it('returns route handler') do
        expect(subject.get("print")).to be_truthy
      end

    end

    context('call route handler') do

      it('successfully call with payload') do
        expect(context_object).to receive(:print).with("print")
        subject.get("print").call("print")
      end

      it('successfully call with payload and headers') do
        expect(context_object).to receive(:print_with_headers)
          .with("print_with_headers", { header: "x" })

        subject.get("print_with_headers")
          .call("print_with_headers", { header: "x" })
      end

    end

  end

end
