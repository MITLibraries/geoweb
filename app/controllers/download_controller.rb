# frozen_string_literal: true
class DownloadController < ApplicationController
  include Blacklight::Catalog

  def file
    @response, @document = search_service.fetch(params[:id])

    if public_file? || current_user
      redirect_to presign_this(s3_key_guesser)
    else
      flash[:error] = 'Authentication required'
      redirect_to solr_document_path(params[:id])
    end
  end

  private

  # Checks whether a document is public, if not require user to authenticate
  def restricted_should_authenticate
    authenticate_user! unless @document.public?
  end

  # The Blacklight way of doing this is to leverage a Presenter.
  # It was unclear whether that could work in a Controller cleanly.
  # It is possible there are other ways GeoBlacklight is determining
  # the ability to download files other than this single field check.
  # Note: We aren't protecting against invalid @document because that
  # seems to be done as part of blacklight.
  def public_file?
    @document[1]._source['dc_rights_s'] == 'Public'
  end

  # All of our files are stored in S3 as zip files. This reconstructs
  # the file name based on how the layer_id_s is being set outside of
  # this app during the data loading process.
  # The same disclaimer about Presenters as in #public_file.
  # Note: We aren't protecting against invalid @document because that
  # seems to be done as part of blacklight.
  def s3_key_guesser
    [@document[1]._source['layer_id_s'].split(':').last, 'zip'].join('.')
  end

  # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Presigner.html
  def presign_this(layer_id_s)
    # for minio
    if Rails.env.test? || Rails.env.development?
      Aws.config[:s3] = { endpoint: ENV['MINIO_URL'], force_path_style: true }
    end

    signer = Aws::S3::Presigner.new
    signer.presigned_url(:get_object, bucket: ENV['AWS_S3_BUCKET'],
                                      key: layer_id_s,
                                      expires_in: 900)
  end
end
