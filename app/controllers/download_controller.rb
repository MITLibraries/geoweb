# frozen_string_literal: true
class DownloadController < ApplicationController
  # include Blacklight::SearchHelper
  include Blacklight::Catalog

  rescue_from Geoblacklight::Exceptions::ExternalDownloadFailed do |exception|
    Geoblacklight.logger.error exception.message + ' ' + exception.url
    flash[:danger] = view_context
                     .tag.span(flash_error_message(exception),
                                  data: {
                                    download: 'error',
                                    download_id: params[:id],
                                    download_type: "generated-#{params[:type]}"
                                  })
    respond_to do |format|
      format.json { render json: flash, response: response }
      format.html { render json: flash, response: response }
    end
  end

  def show
    @response, @document = search_service.fetch params[:id]
    restricted_should_authenticate
    response = check_type
    validate response
    respond_to do |format|
      format.json { render json: flash, response: response }
      format.html { render json: flash, response: response }
    end
  end


  def file
    @response, @document = search_service.fetch(params[:id])

    if public_file? || current_user
      redirect_to presign_this(s3_key_guesser)
    else
      flash[:error] = 'Authentication required'
      redirect_to solr_document_path(params[:id])
    end
  end

  def hgl
    @response, @document = search_service.fetch params[:id]
    if params[:email]
      response = Geoblacklight::HglDownload.new(@document, params[:email]).get
      if response.nil?
        flash[:danger] = t 'geoblacklight.download.error'
      else
        flash[:success] = t 'geoblacklight.download.hgl_success'
      end
      respond_to do |format|
        format.json { render json: flash, response: response }
        format.html { render json: flash, response: response }
      end
    else
      render layout: false
    end
  end

  protected

  ##
  # Creates an error flash message with failed download url
  # @param [Geoblacklight::Exceptions::ExternalDownloadFailed] Download failed
  # exception
  # @return [String] error message to display in flash
  def flash_error_message(exception)
    message = if exception.url.present?
                t('geoblacklight.download.error_with_url',
                            link: view_context
                                  .link_to(exception.url,
                                           exception.url,
                                           target: 'blank'))
                  .html_safe
              else
                t('geoblacklight.download.error')
              end
    message
  end

  private

  def download_file_path_and_name
    "#{Geoblacklight::Download.file_path}/#{params[:id]}.#{params[:format]}"
  end

  def check_type
    response = case params[:type]
               when 'shapefile'
                 Geoblacklight::ShapefileDownload.new(@document).get
               when 'kmz'
                 Geoblacklight::KmzDownload.new(@document).get
               when 'geojson'
                 Geoblacklight::GeojsonDownload.new(@document).get
               when 'geotiff'
                 Geoblacklight::GeotiffDownload.new(@document).get
               end
    response
  end

  def validate(response)
    flash[:success] = view_context.link_to(t('geoblacklight.download.success', title: response),
                                           download_file_path(response),
                                           data: { download: 'trigger',
                                                   download_id: params[:id],
                                                   download_type: "generated-#{params[:type]}" })
  end

  # Checks whether a document is public, if not require user to authenticate
  def restricted_should_authenticate
    authenticate_user! unless @document.public?
  end

  def file_name_to_id(file_name)
    file_name.split('-')[0..-2].join('-')
  end

  private

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
